/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

namespace Jots {

    /**
     * Storage service managing individual Markdown note files in ~/.local/share/<app_id>/notes/
     */
    public class Storage : Object {

        public const string NOTES_DIRNAME = "notes";
        public const string LEGACY_FILENAME = "saved_state.json";

        private File datadir;
        private File notes_dir;
        private string legacy_savefile_path;

        construct {
            var path_data = GLib.Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_user_data_dir (), APP_ID);
            datadir = File.new_for_path (path_data);
            notes_dir = datadir.get_child (NOTES_DIRNAME);
            legacy_savefile_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, path_data, LEGACY_FILENAME);

            ensure_directories ();
            migrate_legacy_json_if_needed ();
        }

        private void ensure_directories () {
            try {
                if (!datadir.query_exists ()) {
                    datadir.make_directory_with_parents ();
                }
                if (!notes_dir.query_exists ()) {
                    notes_dir.make_directory_with_parents ();
                }
            } catch (Error e) {
                warning ("Failed to ensure storage directory: %s", e.message);
            }
        }

        /**
         * Overrides the notes directory for testing environments.
         */
        public void override_notes_dir (string custom_path) {
            notes_dir = File.new_for_path (custom_path);
            try {
                if (!notes_dir.query_exists ()) {
                    notes_dir.make_directory_with_parents ();
                }
            } catch (Error e) {
                warning ("Failed to create override notes directory: %s", e.message);
            }
        }

        public const string JORTS_APP_ID = "io.github.elly_code.jorts";

        private string[]? override_candidate_paths = null;

        /**
         * Overrides candidate legacy search paths for unit testing.
         */
        public void override_legacy_paths (string[] paths) {
            this.override_candidate_paths = paths;
        }

        /**
         * Returns the list of candidate legacy files to search for existing Jorts notes.
         */
        public string[] get_legacy_candidate_paths () {
            if (override_candidate_paths != null) {
                return override_candidate_paths;
            }

            var home = Environment.get_home_dir ();
            var user_data = Environment.get_user_data_dir ();

            return new string[] {
                // 1. Direct Jots legacy backup inside current app data dir (if any)
                legacy_savefile_path,
                // 2. Native / Host Jorts data dir
                GLib.Path.build_path (Path.DIR_SEPARATOR_S, user_data, JORTS_APP_ID, LEGACY_FILENAME),
                // 3. Flatpak Jorts data dir
                GLib.Path.build_path (Path.DIR_SEPARATOR_S, home, ".var", "app", JORTS_APP_ID, "data", JORTS_APP_ID, LEGACY_FILENAME)
            };
        }

        /**
         * Finds and parses notes from legacy Jorts files non-destructively without modifying source files.
         */
        public Gee.List<NoteData> find_legacy_jorts_notes (out string? found_source_path = null) {
            found_source_path = null;
            var list = new Gee.ArrayList<NoteData> ();

            foreach (var path in get_legacy_candidate_paths ()) {
                var file = File.new_for_path (path);
                if (!file.query_exists ()) {
                    continue;
                }

                var parsed = parse_legacy_json_file (path);
                if (parsed.size > 0) {
                    found_source_path = path;
                    return parsed;
                }
            }

            return list;
        }

        /**
         * Helper to parse a JSON array of notes from a file path safely.
         */
        public Gee.List<NoteData> parse_legacy_json_file (string file_path) {
            var list = new Gee.ArrayList<NoteData> ();
            var parser = new Json.Parser ();
            try {
                parser.load_from_mapped_file (file_path);
                var root = parser.get_root ();
                if (root != null && root.get_node_type () == Json.NodeType.ARRAY) {
                    var array = root.get_array ();
                    foreach (var elem in array.get_elements ()) {
                        if (elem.get_node_type () == Json.NodeType.OBJECT) {
                            var obj = elem.dup_object ();
                            var note = new NoteData.from_json (obj);
                            list.add (note);
                        }
                    }
                }
            } catch (Error e) {
                debug ("Could not parse legacy JSON from %s: %s", file_path, e.message);
            }
            return list;
        }

        /**
         * Non-destructively imports a list of notes, saving them as individual Markdown files.
         * Returns the number of imported notes.
         */
        public int import_notes (Gee.List<NoteData> notes) {
            int count = 0;
            foreach (var note in notes) {
                save_note (note);
                count++;
            }
            return count;
        }

        /**
         * Migrates notes from direct legacy saved_state.json within current app data dir if present.
         */
        public void migrate_legacy_json_if_needed () {
            var legacy_file = File.new_for_path (legacy_savefile_path);
            if (!legacy_file.query_exists ()) {
                return;
            }

            // Check if notes directory is already populated
            try {
                var enumerator = notes_dir.enumerate_children (
                    FileAttribute.STANDARD_NAME,
                    FileQueryInfoFlags.NONE
                );
                FileInfo? info = enumerator.next_file ();
                if (info != null) {
                    // Notes directory already has files, do not overwrite with legacy JSON
                    return;
                }
            } catch (Error e) {
                debug ("Checking notes directory: %s", e.message);
            }

            // Perform migration
            debug ("Migrating legacy saved_state.json to markdown files...");
            var parsed = parse_legacy_json_file (legacy_savefile_path);
            if (parsed.size > 0) {
                import_notes (parsed);
                print ("\nSuccessfully migrated %d notes from saved_state.json to Markdown files.\n", parsed.size);
            }

            // Rename direct legacy file to .migrated to preserve safe backup
            try {
                var backup_path = legacy_savefile_path + ".migrated";
                var backup_file = File.new_for_path (backup_path);
                legacy_file.move (backup_file, GLib.FileCopyFlags.OVERWRITE);
            } catch (Error e) {
                warning ("Failed to rename direct legacy backup file: %s", e.message);
            }
        }

        /**
         * Saves an individual note to disk as a Markdown file with YAML front matter.
         */
        public void save_note (NoteData note) {
            ensure_directories ();
            var filename = "%s.md".printf (note.id);
            var file = notes_dir.get_child (filename);
            var md_content = note.to_markdown ();

            try {
                file.replace_contents (
                    md_content.data,
                    null,
                    false,
                    FileCreateFlags.REPLACE_DESTINATION,
                    null
                );
                debug ("Saved note %s to %s", note.id, file.get_path ());
            } catch (Error e) {
                warning ("Failed to save note %s: %s", note.id, e.message);
            }
        }

        /**
         * Deletes an individual note file from disk.
         */
        public void delete_note (string note_id) {
            var filename = "%s.md".printf (note_id);
            var file = notes_dir.get_child (filename);
            if (file.query_exists ()) {
                try {
                    file.delete ();
                    debug ("Deleted note file: %s", file.get_path ());
                } catch (Error e) {
                    warning ("Failed to delete note file %s: %s", note_id, e.message);
                }
            }
        }

        /**
         * Loads a single note by its ID from the notes directory.
         */
        public NoteData? load_note_by_id (string note_id) {
            ensure_directories ();
            var filename = "%s.md".printf (note_id);
            var file = notes_dir.get_child (filename);
            if (!file.query_exists ()) {
                return null;
            }
            try {
                uint8[] contents;
                string etag;
                file.load_contents (null, out contents, out etag);
                var raw_str = (string) contents;
                return MarkdownSerializer.deserialize (raw_str, note_id);
            } catch (Error e) {
                warning ("Failed to load note file %s: %s", filename, e.message);
                return null;
            }
        }

        /**
         * Loads all Markdown note files from the notes directory.
         */
        public Gee.ArrayList<NoteData> load_all () {
            ensure_directories ();
            migrate_legacy_json_if_needed ();

            var list = new Gee.ArrayList<NoteData> ();

            try {
                var enumerator = notes_dir.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo? info = null;
                while ((info = enumerator.next_file ()) != null) {
                    var name = info.get_name ();
                    if (!name.has_suffix (".md")) {
                        continue;
                    }

                    var file = notes_dir.get_child (name);
                    try {
                        uint8[] contents;
                        string etag;
                        file.load_contents (null, out contents, out etag);
                        var raw_str = (string) contents;

                        // Use filename base as fallback id
                        var base_id = name.substring (0, name.length - 3);
                        var note = MarkdownSerializer.deserialize (raw_str, base_id);
                        list.add (note);
                    } catch (Error err) {
                        warning ("Failed to load note file %s: %s", name, err.message);
                    }
                }
            } catch (Error e) {
                warning ("Failed to enumerate notes directory: %s", e.message);
            }

            debug ("Loaded %d notes from markdown storage.", list.size);
            return list;
        }

        /**
         * Convenience legacy wrapper returning Json.Array for backward compatibility.
         */
        public Json.Array load () {
            var notes = load_all ();
            var array = new Json.Array ();
            foreach (var note in notes) {
                array.add_object_element (note.to_json ());
            }
            return array;
        }

        /**
         * Convenience legacy wrapper saving a Json.Array to markdown files.
         */
        public void save (Json.Array json_data) {
            foreach (var elem in json_data.get_elements ()) {
                var obj = elem.dup_object ();
                var note = new NoteData.from_json (obj);
                save_note (note);
            }
        }
    }
}
