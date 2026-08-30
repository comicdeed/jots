/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    public enum BackupChangeType {
        TEXT,
        METADATA
    }

    public class BackupCommitIntent : Object {
        public string note_id { get; set; }
        public string note_path { get; set; }
        public bool deleted { get; set; }
        public BackupChangeType change_type { get; set; }
        public int64 due_usec { get; set; }

        public BackupCommitIntent (string note_id, string note_path, bool deleted, BackupChangeType change_type, int64 due_usec) {
            this.note_id = note_id;
            this.note_path = note_path;
            this.deleted = deleted;
            this.change_type = change_type;
            this.due_usec = due_usec;
        }
    }

    public class GitCommandResult : Object {
        public bool success { get; set; }
        public string stdout_text { get; set; }
        public string stderr_text { get; set; }

        public GitCommandResult (bool success, string stdout_text, string stderr_text) {
            this.success = success;
            this.stdout_text = stdout_text;
            this.stderr_text = stderr_text;
        }
    }

    /**
     * Coordinates local Git backup groundwork and reacts to internal storage events.
     */
    public class GitSyncService : Object {

        private const int64 COMMIT_DEBOUNCE_USEC = 120 * 1000 * 1000;
        private const uint STATUS_POLL_INTERVAL_MS = 300 * 1000;
        private const int BACKUP_CADENCE_DISABLED = 0;
        private const int BACKUP_CADENCE_EVERY_5_MIN = 1;
        private const int BACKUP_CADENCE_EVERY_15_MIN = 2;
        private const int BACKUP_CADENCE_EVERY_30_MIN = 3;
        private const int BACKUP_CADENCE_HOURLY = 4;
        private const string GITIGNORE_CANONICAL = "*\n!.gitignore\n!*/\n!*.md\n";

        private Storage storage;
        private GLib.Settings settings;
        private bool enabled = false;
        private bool gitignore_warning_emitted = false;
        private bool bootstrap_in_progress = false;
        private bool execution_in_progress = false;
        private bool status_poll_in_progress = false;
        private bool remote_sync_in_progress = false;
        private uint64 execution_epoch = 0;
        private uint debounce_timer_id = 0;
        private uint status_poll_timer_id = 0;
        private uint remote_sync_timer_id = 0;
        private Gee.HashMap<string, BackupCommitIntent> pending_intents = new Gee.HashMap<string, BackupCommitIntent> ();
        private Gee.ArrayList<BackupCommitIntent> execution_queue = new Gee.ArrayList<BackupCommitIntent> ();

        public GitSyncService (Storage storage, GLib.Settings settings) {
            this.storage = storage;
            this.settings = settings;
        }

        public void initialize () {
            storage.note_saved.connect (on_note_saved);
            storage.note_deleted.connect (on_note_deleted);
            settings.changed[KEY_BACKUP_SYNC_ENABLED].connect (() => {
                enabled = settings.get_boolean (KEY_BACKUP_SYNC_ENABLED);
                execution_epoch++;
                if (enabled) {
                    enable_backup_async.begin (execution_epoch);
                } else {
                    clear_pending_intents ();
                    stop_status_poll_timer ();
                    stop_remote_sync_timer ();
                    set_status (BACKUP_STATUS_DISABLED);
                }
            });
            settings.changed[KEY_BACKUP_SYNC_CADENCE].connect (() => {
                if (!enabled) {
                    return;
                }

                refresh_remote_sync_schedule (execution_epoch);
            });
            settings.changed[KEY_BACKUP_SYNC_REMOTE_URL].connect (() => {
                if (!enabled) {
                    return;
                }

                refresh_remote_sync_schedule (execution_epoch);
            });

            enabled = settings.get_boolean (KEY_BACKUP_SYNC_ENABLED);
            execution_epoch++;
            if (enabled) {
                enable_backup_async.begin (execution_epoch);
            } else {
                set_status (BACKUP_STATUS_DISABLED);
            }
        }

        public void shutdown () {
            clear_pending_intents ();
            stop_status_poll_timer ();
            stop_remote_sync_timer ();
        }

        public void request_remote_sync_now () {
            if (!enabled) {
                set_status (BACKUP_STATUS_DISABLED);
                return;
            }

            synchronize_remote_async.begin (execution_epoch);
        }

        public async bool test_remote_connection_async () {
            if (!enabled) {
                set_status (BACKUP_STATUS_DISABLED);
                return false;
            }

            var remote_url = settings.get_string (KEY_BACKUP_SYNC_REMOTE_URL).strip ();
            if (remote_url == "") {
                set_status (BACKUP_STATUS_REMOTE_NOT_CONFIGURED);
                return false;
            }

            if (!(yield ensure_repository_async ()) || !(yield ensure_git_identity_async ()) || !ensure_managed_gitignore ()) {
                set_status (BACKUP_STATUS_ERROR);
                return false;
            }

            set_status (BACKUP_STATUS_TESTING_REMOTE);
            var probe_result = yield run_git_command_async ({"ls-remote", "--heads", remote_url});
            if (!probe_result.success) {
                warning ("Remote connectivity check failed: %s", probe_result.stderr_text);
                set_status (BACKUP_STATUS_REMOTE_UNREACHABLE);
                return false;
            }

            set_status (BACKUP_STATUS_REMOTE_REACHABLE);
            return true;
        }

        private async void enable_backup_async (uint64 epoch) {
            if (bootstrap_in_progress) {
                return;
            }

            bootstrap_in_progress = true;
            set_status (BACKUP_STATUS_PREPARING);
            if (!enabled || epoch != execution_epoch) {
                bootstrap_in_progress = false;
                return;
            }

            if (!yield ensure_repository_async ()) {
                bootstrap_in_progress = false;
                return;
            }

            if (!enabled || epoch != execution_epoch) {
                bootstrap_in_progress = false;
                return;
            }

            if (!yield ensure_git_identity_async ()) {
                bootstrap_in_progress = false;
                return;
            }

            if (!enabled || epoch != execution_epoch) {
                bootstrap_in_progress = false;
                return;
            }

            if (!ensure_managed_gitignore ()) {
                bootstrap_in_progress = false;
                return;
            }

            if (enabled && epoch == execution_epoch) {
                set_status (BACKUP_STATUS_REPOSITORY_READY);
                start_status_poll_timer (epoch);
                refresh_remote_sync_schedule (epoch);
            }
            bootstrap_in_progress = false;

            if (enabled && epoch != execution_epoch) {
                enable_backup_async.begin (execution_epoch);
            }
        }

        private void on_note_saved (NoteData note, NoteData? previous_note, string note_path) {
            if (!enabled) {
                return;
            }

            var change_type = classify_change (note, previous_note);
            queue_commit_intent (note.id, note_path, false, change_type);
            set_status (BACKUP_STATUS_PENDING);
        }

        private void on_note_deleted (string note_id, string note_path) {
            if (!enabled) {
                return;
            }

            queue_commit_intent (note_id, note_path, true, BackupChangeType.TEXT);
            set_status (BACKUP_STATUS_PENDING);
        }

        private void queue_commit_intent (string note_id, string note_path, bool deleted, BackupChangeType change_type) {
            int64 now = GLib.get_monotonic_time ();
            int64 due = now + COMMIT_DEBOUNCE_USEC;

            var intent = new BackupCommitIntent (note_id, note_path, deleted, change_type, due);
            pending_intents.set (note_path, intent);
            arm_debounce_timer_to_earliest ();
        }

        private void arm_debounce_timer_to_earliest () {
            if (pending_intents.size == 0) {
                if (debounce_timer_id != 0) {
                    Source.remove (debounce_timer_id);
                    debounce_timer_id = 0;
                }
                return;
            }

            int64 earliest_due = int64.MAX;
            foreach (var intent in pending_intents.values) {
                if (intent.due_usec < earliest_due) {
                    earliest_due = intent.due_usec;
                }
            }

            int64 now = GLib.get_monotonic_time ();
            int64 delta_usec = earliest_due - now;
            uint delay_ms = 1;
            if (delta_usec > 0) {
                delay_ms = (uint) ((delta_usec + 999) / 1000);
            }

            if (debounce_timer_id != 0) {
                Source.remove (debounce_timer_id);
                debounce_timer_id = 0;
            }

            debounce_timer_id = Timeout.add (delay_ms, () => {
                debounce_timer_id = 0;
                drain_due_intents ();
                return Source.REMOVE;
            });
        }

        private void drain_due_intents () {
            if (!enabled) {
                return;
            }

            int64 now = GLib.get_monotonic_time ();
            var due_paths = new Gee.ArrayList<string> ();

            foreach (var entry in pending_intents.entries) {
                if (entry.value.due_usec <= now) {
                    due_paths.add (entry.key);
                }
            }

            foreach (var path in due_paths) {
                var intent = pending_intents.get (path);
                if (intent == null) {
                    continue;
                }

                execution_queue.add (intent);
                pending_intents.unset (path);
            }

            if (pending_intents.size > 0) {
                arm_debounce_timer_to_earliest ();
            }

            if (execution_queue.size > 0) {
                process_execution_queue_async.begin (execution_epoch);
                return;
            }

            if (enabled && pending_intents.size == 0) {
                set_status (BACKUP_STATUS_REPOSITORY_READY);
            }
        }

        private async void process_execution_queue_async (uint64 epoch) {
            if (execution_in_progress) {
                return;
            }

            execution_in_progress = true;
            while (enabled && epoch == execution_epoch && execution_queue.size > 0) {
                var intent = execution_queue.remove_at (0);
                yield execute_debounced_intent_async (intent, epoch);
            }

            execution_in_progress = false;
            if (enabled && epoch == execution_epoch && pending_intents.size == 0) {
                set_status (BACKUP_STATUS_REPOSITORY_READY);
            }
        }

        private async void execute_debounced_intent_async (BackupCommitIntent intent, uint64 epoch) {
            if (!enabled || epoch != execution_epoch) {
                return;
            }

            if (!(yield ensure_repository_async ()) || !(yield ensure_git_identity_async ()) || !ensure_managed_gitignore ()) {
                return;
            }

            if (!enabled || epoch != execution_epoch) {
                return;
            }

            var change_label = intent.change_type == BackupChangeType.TEXT ? "text" : "metadata";
            var tracked_filename = File.new_for_path (intent.note_path).get_basename ();

            if (intent.deleted) {
                var rm_result = yield run_git_command_async ({"rm", "--quiet", "--ignore-unmatch", tracked_filename});
                if (!enabled || epoch != execution_epoch) {
                    return;
                }

                if (!rm_result.success) {
                    warning ("Git remove failed for %s: %s", tracked_filename, rm_result.stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    return;
                }

                var delete_message = "backup(note): delete %s (text)".printf (intent.note_id);
                if (yield commit_staged_changes_async (delete_message, epoch)) {
                    set_last_sync_now ();
                }

                return;
            }

            var add_result = yield run_git_command_async ({"add", tracked_filename});
            if (!enabled || epoch != execution_epoch) {
                return;
            }

            if (!add_result.success) {
                warning ("Git add failed for %s: %s", tracked_filename, add_result.stderr_text);
                set_status (BACKUP_STATUS_ERROR);
                return;
            }

            var update_message = "backup(note): update %s (%s)".printf (intent.note_id, change_label);
            if (yield commit_staged_changes_async (update_message, epoch)) {
                set_last_sync_now ();
            }
        }

        private async bool commit_staged_changes_async (string commit_message, uint64 epoch) {
            if (!enabled || epoch != execution_epoch) {
                return false;
            }

            var commit_result = yield run_git_command_async ({"commit", "-m", commit_message});
            if (!enabled || epoch != execution_epoch) {
                return false;
            }

            if (commit_result.success) {
                set_status (BACKUP_STATUS_LOCAL_COMMIT_CREATED);
                return true;
            }

            if (is_empty_commit_result (commit_result.stdout_text, commit_result.stderr_text)) {
                debug ("Skipping empty commit for '%s'", commit_message);
                return false;
            }

            warning ("Git commit failed for '%s': %s", commit_message, commit_result.stderr_text);
            set_status (BACKUP_STATUS_ERROR);
            return false;
        }

        private bool is_empty_commit_result (string stdout_text, string stderr_text) {
            var combined = (stdout_text + "\n" + stderr_text).down ();
            return combined.contains ("nothing to commit") || combined.contains ("no changes added to commit");
        }

        private void set_last_sync_now () {
            if (!enabled) {
                return;
            }

            var now = new DateTime.now_local ();
            settings.set_string (KEY_BACKUP_SYNC_LAST_SYNC, now.format ("%Y-%m-%d %H:%M"));
        }

        private void clear_pending_intents () {
            pending_intents.clear ();
            execution_queue.clear ();
            if (debounce_timer_id != 0) {
                Source.remove (debounce_timer_id);
                debounce_timer_id = 0;
            }
        }

        private void start_status_poll_timer (uint64 epoch) {
            stop_status_poll_timer ();
            status_poll_timer_id = Timeout.add (STATUS_POLL_INTERVAL_MS, () => {
                if (!enabled || epoch != execution_epoch) {
                    return Source.REMOVE;
                }

                poll_external_state_async.begin (epoch);
                return Source.CONTINUE;
            });

            poll_external_state_async.begin (epoch);
        }

        private void stop_status_poll_timer () {
            if (status_poll_timer_id != 0) {
                Source.remove (status_poll_timer_id);
                status_poll_timer_id = 0;
            }
        }

        private void refresh_remote_sync_schedule (uint64 epoch) {
            stop_remote_sync_timer ();
            if (!enabled || epoch != execution_epoch) {
                return;
            }

            var remote_url = settings.get_string (KEY_BACKUP_SYNC_REMOTE_URL).strip ();
            if (remote_url == "") {
                set_status (BACKUP_STATUS_REMOTE_NOT_CONFIGURED);
                return;
            }

            uint interval_ms = cadence_interval_ms_for (settings.get_enum (KEY_BACKUP_SYNC_CADENCE));
            if (interval_ms == 0) {
                return;
            }

            remote_sync_timer_id = Timeout.add (interval_ms, () => {
                if (!enabled || epoch != execution_epoch) {
                    return Source.REMOVE;
                }

                synchronize_remote_async.begin (epoch);
                return Source.CONTINUE;
            });
        }

        private void stop_remote_sync_timer () {
            if (remote_sync_timer_id != 0) {
                Source.remove (remote_sync_timer_id);
                remote_sync_timer_id = 0;
            }
        }

        private async void synchronize_remote_async (uint64 epoch) {
            if (remote_sync_in_progress || !enabled || epoch != execution_epoch) {
                return;
            }

            if (pending_intents.size > 0 || execution_queue.size > 0 || execution_in_progress) {
                return;
            }

            var remote_url = settings.get_string (KEY_BACKUP_SYNC_REMOTE_URL).strip ();
            if (remote_url == "") {
                set_status (BACKUP_STATUS_REMOTE_NOT_CONFIGURED);
                return;
            }

            remote_sync_in_progress = true;
            set_status (BACKUP_STATUS_SYNCING_REMOTE);

            if (!(yield ensure_repository_async ()) || !(yield ensure_git_identity_async ()) || !ensure_managed_gitignore ()) {
                remote_sync_in_progress = false;
                return;
            }

            if (!enabled || epoch != execution_epoch) {
                remote_sync_in_progress = false;
                return;
            }

            if (!(yield ensure_remote_origin_url_async (remote_url))) {
                set_status (BACKUP_STATUS_ERROR);
                remote_sync_in_progress = false;
                return;
            }

            var branch_name = yield get_current_branch_async ();
            if (!enabled || epoch != execution_epoch) {
                remote_sync_in_progress = false;
                return;
            }

            if (branch_name == null || branch_name.strip () == "") {
                warning ("Unable to resolve local branch name for remote sync");
                set_status (BACKUP_STATUS_ERROR);
                remote_sync_in_progress = false;
                return;
            }

            var fetch_result = yield run_git_command_async ({"fetch", "--quiet", "origin"});
            if (!enabled || epoch != execution_epoch) {
                remote_sync_in_progress = false;
                return;
            }

            if (!fetch_result.success) {
                warning ("Git fetch failed: %s", fetch_result.stderr_text);
                set_status (BACKUP_STATUS_ERROR);
                remote_sync_in_progress = false;
                return;
            }

            bool remote_branch_exists = yield remote_branch_exists_async (branch_name);
            if (!enabled || epoch != execution_epoch) {
                remote_sync_in_progress = false;
                return;
            }

            int behind = 0;
            int ahead = 0;
            if (remote_branch_exists) {
                var counts = yield run_git_command_async ({"rev-list", "--left-right", "--count", ("origin/" + branch_name) + "...HEAD"});
                if (!enabled || epoch != execution_epoch) {
                    remote_sync_in_progress = false;
                    return;
                }

                if (!counts.success || !try_parse_upstream_counts (counts.stdout_text, out behind, out ahead)) {
                    warning ("Unable to parse remote divergence counts: %s", counts.stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    remote_sync_in_progress = false;
                    return;
                }
            } else {
                ahead = 1;
                behind = 0;
            }

            if (remote_branch_exists && behind > 0 && ahead > 0) {
                set_status (BACKUP_STATUS_REMOTE_DIVERGED);
                remote_sync_in_progress = false;
                return;
            }

            if (remote_branch_exists && behind > 0) {
                var pull_result = yield run_git_command_async ({"pull", "--rebase", "origin", branch_name});
                if (!enabled || epoch != execution_epoch) {
                    remote_sync_in_progress = false;
                    return;
                }

                if (!pull_result.success) {
                    warning ("Git pull --rebase failed: %s", pull_result.stderr_text);
                    set_status (BACKUP_STATUS_REMOTE_DIVERGED);
                    remote_sync_in_progress = false;
                    return;
                }
            }

            if (ahead > 0 || !remote_branch_exists) {
                var push_result = yield run_git_command_async ({"push", "--quiet", "origin", ("HEAD:" + branch_name)});
                if (!enabled || epoch != execution_epoch) {
                    remote_sync_in_progress = false;
                    return;
                }

                if (!push_result.success) {
                    warning ("Git push failed: %s", push_result.stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    remote_sync_in_progress = false;
                    return;
                }

                set_last_sync_now ();
                set_status (BACKUP_STATUS_REMOTE_SYNCED);
                remote_sync_in_progress = false;
                return;
            }

            set_status (BACKUP_STATUS_REPOSITORY_READY);
            remote_sync_in_progress = false;
        }

        private async bool ensure_remote_origin_url_async (string remote_url) {
            var current_remote = yield run_git_command_async ({"remote", "get-url", "origin"});
            if (current_remote.success) {
                var current = current_remote.stdout_text.strip ();
                if (current == remote_url) {
                    return true;
                }

                var set_url = yield run_git_command_async ({"remote", "set-url", "origin", remote_url});
                return set_url.success;
            }

            var add_remote = yield run_git_command_async ({"remote", "add", "origin", remote_url});
            return add_remote.success;
        }

        private async string? get_current_branch_async () {
            var branch_result = yield run_git_command_async ({"rev-parse", "--abbrev-ref", "HEAD"});
            if (!branch_result.success) {
                return null;
            }

            var branch = branch_result.stdout_text.strip ();
            if (branch == "" || branch == "HEAD") {
                return null;
            }

            return branch;
        }

        private async bool remote_branch_exists_async (string branch_name) {
            var show_ref = yield run_git_command_async ({"show-ref", "--verify", "--quiet", "refs/remotes/origin/" + branch_name});
            return show_ref.success;
        }

        internal static uint cadence_interval_ms_for (int cadence_value) {
            switch (cadence_value) {
            case BACKUP_CADENCE_EVERY_5_MIN:
                return 5 * 60 * 1000;
            case BACKUP_CADENCE_EVERY_15_MIN:
                return 15 * 60 * 1000;
            case BACKUP_CADENCE_EVERY_30_MIN:
                return 30 * 60 * 1000;
            case BACKUP_CADENCE_HOURLY:
                return 60 * 60 * 1000;
            case BACKUP_CADENCE_DISABLED:
            default:
                return 0;
            }
        }

        private async void poll_external_state_async (uint64 epoch) {
            if (status_poll_in_progress || !enabled || epoch != execution_epoch) {
                return;
            }

            status_poll_in_progress = true;

            if (!(yield ensure_repository_async ()) || !enabled || epoch != execution_epoch) {
                status_poll_in_progress = false;
                return;
            }

            var status_result = yield run_git_command_async ({"status", "--porcelain"});
            if (!enabled || epoch != execution_epoch) {
                status_poll_in_progress = false;
                return;
            }

            if (!status_result.success) {
                warning ("Git status poll failed: %s", status_result.stderr_text);
                set_status (BACKUP_STATUS_ERROR);
                status_poll_in_progress = false;
                return;
            }

            bool has_internal_work = pending_intents.size > 0 || execution_queue.size > 0 || execution_in_progress;
            bool has_external_worktree_changes = status_result.stdout_text.strip () != "";

            if (!has_internal_work && has_external_worktree_changes) {
                set_status (BACKUP_STATUS_EXTERNAL_CHANGES_DETECTED);
                status_poll_in_progress = false;
                return;
            }

            var upstream_result = yield run_git_command_async ({"rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"});
            if (!enabled || epoch != execution_epoch) {
                status_poll_in_progress = false;
                return;
            }

            if (upstream_result.success) {
                var counts = yield run_git_command_async ({"rev-list", "--left-right", "--count", "@{upstream}...HEAD"});
                if (!enabled || epoch != execution_epoch) {
                    status_poll_in_progress = false;
                    return;
                }

                int behind = 0;
                int ahead = 0;
                if (counts.success && try_parse_upstream_counts (counts.stdout_text, out behind, out ahead)) {
                    if (!has_internal_work && (ahead > 0 || behind > 0)) {
                        set_status (BACKUP_STATUS_REMOTE_DIVERGED);
                        status_poll_in_progress = false;
                        return;
                    }
                }
            }

            if (!has_internal_work) {
                set_status (BACKUP_STATUS_REPOSITORY_READY);
            }

            status_poll_in_progress = false;
        }

        internal static bool try_parse_upstream_counts (string raw, out int behind, out int ahead) {
            behind = 0;
            ahead = 0;

            var normalized = raw.strip ().replace ("\t", " ");
            if (normalized == "") {
                return false;
            }

            string[] parts = normalized.split (" ");
            var compact = new Gee.ArrayList<string> ();
            foreach (var part in parts) {
                var trimmed = part.strip ();
                if (trimmed != "") {
                    compact.add (trimmed);
                }
            }

            if (compact.size < 2) {
                return false;
            }

            int64 behind64 = 0;
            int64 ahead64 = 0;
            if (!int64.try_parse (compact.get (0), out behind64) || !int64.try_parse (compact.get (1), out ahead64)) {
                return false;
            }

            if (behind64 < 0 || behind64 > int.MAX || ahead64 < 0 || ahead64 > int.MAX) {
                return false;
            }

            behind = (int) behind64;
            ahead = (int) ahead64;
            return true;
        }

        private BackupChangeType classify_change (NoteData note, NoteData? previous_note) {
            if (previous_note == null) {
                return BackupChangeType.TEXT;
            }

            if (note.content != previous_note.content) {
                return BackupChangeType.TEXT;
            }

            return BackupChangeType.METADATA;
        }

        private async bool ensure_repository_async () {
            var notes_dir = storage.get_notes_dir ();
            var git_dir = notes_dir.get_child (".git");
            if (git_dir.query_exists ()) {
                return true;
            }

            var init_result = yield run_git_command_async ({"init", "-q"});
            if (!init_result.success) {
                warning ("Git repository bootstrap failed: %s", init_result.stderr_text);
                set_status (BACKUP_STATUS_ERROR);
                return false;
            }

            debug ("Initialized local notes repository at %s", notes_dir.get_path ());
            return true;
        }

        private async bool ensure_git_identity_async () {
            var has_name = yield run_git_command_async ({"config", "--local", "--get", "user.name"});
            if (!has_name.success) {
                var set_name = yield run_git_command_async ({"config", "--local", "user.name", "Jots Backup"});
                if (!set_name.success) {
                    warning ("Failed to set local git user.name: %s", set_name.stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    return false;
                }
            }

            var has_email = yield run_git_command_async ({"config", "--local", "--get", "user.email"});
            if (!has_email.success) {
                var set_email = yield run_git_command_async ({"config", "--local", "user.email", "jots-backup@localhost"});
                if (!set_email.success) {
                    warning ("Failed to set local git user.email: %s", set_email.stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    return false;
                }
            }

            return true;
        }

        private bool ensure_managed_gitignore () {
            var notes_dir = storage.get_notes_dir ();
            var gitignore = notes_dir.get_child (".gitignore");
            var expected_hash = checksum_for (GITIGNORE_CANONICAL);

            bool drift_detected = false;
            if (gitignore.query_exists ()) {
                try {
                    uint8[] bytes;
                    string etag;
                    gitignore.load_contents (null, out bytes, out etag);
                    var current_text = (string) bytes;
                    drift_detected = checksum_for (current_text) != expected_hash;
                } catch (Error e) {
                    warning ("Failed to read managed .gitignore: %s", e.message);
                    set_status (BACKUP_STATUS_ERROR);
                    return false;
                }
            } else {
                drift_detected = true;
            }

            if (drift_detected) {
                if (!write_gitignore (gitignore)) {
                    set_status (BACKUP_STATUS_ERROR);
                    return false;
                }

                var prior_hash = settings.get_string (KEY_BACKUP_SYNC_GITIGNORE_SHA);
                if (prior_hash != "" && !gitignore_warning_emitted) {
                    set_status (BACKUP_STATUS_GITIGNORE_RESTORED);
                    gitignore_warning_emitted = true;
                }
            }

            settings.set_string (KEY_BACKUP_SYNC_GITIGNORE_SHA, expected_hash);
            return true;
        }

        private bool write_gitignore (File gitignore) {
            try {
                gitignore.replace_contents (
                    GITIGNORE_CANONICAL.data,
                    null,
                    false,
                    FileCreateFlags.REPLACE_DESTINATION,
                    null
                );
                return true;
            } catch (Error e) {
                warning ("Failed to write managed .gitignore: %s", e.message);
                return false;
            }
        }

        private string checksum_for (string input) {
            var checksum = new Checksum (ChecksumType.SHA256);
            checksum.update (input.data, input.length);
            return checksum.get_string ();
        }

        private async GitCommandResult run_git_command_async (string[] args) {
            string stdout_text = "";
            string stderr_text = "";

            var argv = new string[args.length + 1];
            argv[0] = "git";
            for (int i = 0; i < args.length; i++) {
                argv[i + 1] = args[i];
            }

            try {
                var launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE);
                launcher.set_cwd (storage.get_notes_dir_path ());
                launcher.setenv ("GIT_TERMINAL_PROMPT", "0", true);
                var process = launcher.spawnv (argv);
                yield process.communicate_utf8_async (null, null, out stdout_text, out stderr_text);
                return new GitCommandResult (process.get_successful (), stdout_text ?? "", stderr_text ?? "");
            } catch (Error e) {
                return new GitCommandResult (false, "", e.message);
            }
        }

        private void set_status (string status_text) {
            settings.set_string (KEY_BACKUP_SYNC_STATUS, status_text);
        }
    }
}
