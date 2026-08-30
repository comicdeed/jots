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
        private const string GITIGNORE_CANONICAL = "*\n!.gitignore\n!*/\n!*.md\n";

        private Storage storage;
        private GLib.Settings settings;
        private bool enabled = false;
        private bool gitignore_warning_emitted = false;
        private bool bootstrap_in_progress = false;
        private bool execution_in_progress = false;
        private uint64 execution_epoch = 0;
        private uint debounce_timer_id = 0;
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
                    set_status (BACKUP_STATUS_DISABLED);
                }
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
