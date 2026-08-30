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

    /**
     * Coordinates local Git backup groundwork and reacts to internal storage events.
     */
    public class GitSyncService : Object {

        private const int64 COMMIT_DEBOUNCE_USEC = 120 * 1000 * 1000;
        private const string GITIGNORE_CANONICAL = "*\n!.gitignore\n!*/\n!*.md\n";

        private weak Storage storage;
        private GLib.Settings settings;
        private bool enabled = false;
        private bool gitignore_warning_emitted = false;
        private uint debounce_timer_id = 0;
        private Gee.HashMap<string, BackupCommitIntent> pending_intents = new Gee.HashMap<string, BackupCommitIntent> ();

        public GitSyncService (Storage storage, GLib.Settings settings) {
            this.storage = storage;
            this.settings = settings;
        }

        public void initialize () {
            storage.note_saved.connect (on_note_saved);
            storage.note_deleted.connect (on_note_deleted);
            settings.changed[KEY_BACKUP_SYNC_ENABLED].connect (() => {
                enabled = settings.get_boolean (KEY_BACKUP_SYNC_ENABLED);
                if (enabled) {
                    enable_backup ();
                } else {
                    clear_pending_intents ();
                    set_status (BACKUP_STATUS_DISABLED);
                }
            });

            enabled = settings.get_boolean (KEY_BACKUP_SYNC_ENABLED);
            if (enabled) {
                enable_backup ();
            } else {
                set_status (BACKUP_STATUS_DISABLED);
            }
        }

        public void shutdown () {
            clear_pending_intents ();
        }

        private void enable_backup () {
            set_status (BACKUP_STATUS_PREPARING);
            if (!ensure_repository ()) {
                return;
            }

            if (!ensure_git_identity ()) {
                return;
            }

            if (!ensure_managed_gitignore ()) {
                return;
            }

            set_status (BACKUP_STATUS_READY);
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

                execute_debounced_intent (intent);
                pending_intents.unset (path);
            }

            if (pending_intents.size > 0) {
                arm_debounce_timer_to_earliest ();
                return;
            }

            set_status (BACKUP_STATUS_READY);
        }

        private void execute_debounced_intent (BackupCommitIntent intent) {
            // Commit execution will be implemented in the next phase.
            if (intent.deleted) {
                debug ("Debounce expired: delete %s (%s)", intent.note_id, intent.note_path);
                return;
            }

            var change_label = intent.change_type == BackupChangeType.TEXT ? "text" : "metadata";
            debug ("Debounce expired: update %s (%s) at %s", intent.note_id, change_label, intent.note_path);
        }

        private void clear_pending_intents () {
            pending_intents.clear ();
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

        private bool ensure_repository () {
            var notes_dir = storage.get_notes_dir ();
            var git_dir = notes_dir.get_child (".git");
            if (git_dir.query_exists ()) {
                return true;
            }

            string stdout_text;
            string stderr_text;
            if (!run_git_command ({"init", "-q"}, out stdout_text, out stderr_text)) {
                warning ("Git repository bootstrap failed: %s", stderr_text);
                set_status (BACKUP_STATUS_ERROR);
                return false;
            }

            debug ("Initialized local notes repository at %s", notes_dir.get_path ());
            return true;
        }

        private bool ensure_git_identity () {
            string stdout_text;
            string stderr_text;

            bool has_name = run_git_command ({"config", "--local", "--get", "user.name"}, out stdout_text, out stderr_text);
            if (!has_name) {
                if (!run_git_command ({"config", "--local", "user.name", "Jots Backup"}, out stdout_text, out stderr_text)) {
                    warning ("Failed to set local git user.name: %s", stderr_text);
                    set_status (BACKUP_STATUS_ERROR);
                    return false;
                }
            }

            bool has_email = run_git_command ({"config", "--local", "--get", "user.email"}, out stdout_text, out stderr_text);
            if (!has_email) {
                if (!run_git_command ({"config", "--local", "user.email", "jots-backup@localhost"}, out stdout_text, out stderr_text)) {
                    warning ("Failed to set local git user.email: %s", stderr_text);
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

        private bool run_git_command (string[] args, out string stdout_text, out string stderr_text) {
            stdout_text = "";
            stderr_text = "";

            var argv = new string[args.length + 1];
            argv[0] = "git";
            for (int i = 0; i < args.length; i++) {
                argv[i + 1] = args[i];
            }

            try {
                var launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE);
                launcher.set_cwd (storage.get_notes_dir_path ());
                var process = launcher.spawnv (argv);
                process.communicate_utf8 (null, null, out stdout_text, out stderr_text);
                return process.get_successful ();
            } catch (Error e) {
                stderr_text = e.message;
                return false;
            }
        }

        private void set_status (string status_text) {
            settings.set_string (KEY_BACKUP_SYNC_STATUS, status_text);
        }
    }
}
