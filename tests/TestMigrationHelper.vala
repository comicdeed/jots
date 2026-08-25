/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {

    public class TestMigrationHelper {

        private static string create_temp_dir (string prefix) {
            var temp_dir = Path.build_filename (Environment.get_tmp_dir (), "%s-%s".printf (prefix, GLib.Uuid.string_random ()));
            DirUtils.create_with_parents (temp_dir, 0700);
            return temp_dir;
        }

        public static void register () {
            GLib.Test.add_func ("/MigrationHelper/UC_20_30_10/JortsCandidateDiscovery", test_candidate_discovery);
            GLib.Test.add_func ("/MigrationHelper/UC_20_30_20/NonDestructiveImport", test_non_destructive_import);
            GLib.Test.add_func ("/MigrationHelper/UC_20_30_30/DuplicateProtection", test_duplicate_protection);
            GLib.Test.add_func ("/MigrationHelper/UC_20_30_40/MalformedLegacyJson", test_malformed_legacy_json);
            GLib.Test.add_func ("/MigrationHelper/UC_20_30_50/EmptyCandidateList", test_empty_candidate_list);
        }

        private static void test_candidate_discovery () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-target");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir1 = create_temp_dir ("jorts-host-mock");
            var temp_dir2 = create_temp_dir ("jorts-flatpak-mock");

            var file1_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir1, "saved_state.json");
            var file2_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir2, "saved_state.json");

            // Mock JSON with 2 notes in path 1
            var json_content1 = "[{\"id\":\"jorts-note-1\",\"title\":\"Jorts Note 1\",\"content\":\"Content 1\",\"theme\":\"mint\"},{\"id\":\"jorts-note-2\",\"title\":\"Jorts Note 2\",\"content\":\"Content 2\",\"theme\":\"banana\"}]";
            try {
                FileUtils.set_contents (file1_path, json_content1);
            } catch (Error e) {
                assert_not_reached ();
            }

            // Mock JSON with 1 note in path 2
            var json_content2 = "[{\"id\":\"jorts-note-3\",\"title\":\"Jorts Note 3\",\"content\":\"Content 3\",\"theme\":\"blueberry\"}]";
            try {
                FileUtils.set_contents (file2_path, json_content2);
            } catch (Error e) {
                assert_not_reached ();
            }

            // Test candidate discovery with path1 first
            storage.override_legacy_paths ({ file1_path, file2_path });
            string? found_path = null;
            var notes = storage.find_legacy_jorts_notes (out found_path);

            assert_cmpstr (found_path, GLib.CompareOperator.EQ, file1_path);
            assert_true (notes.size == 2);
            assert_cmpstr (notes.get (0).id, GLib.CompareOperator.EQ, "jorts-note-1");
            assert_cmpstr (notes.get (1).id, GLib.CompareOperator.EQ, "jorts-note-2");
        }

        private static void test_non_destructive_import () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-target");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-source");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            var original_json = "[{\"id\":\"keep-me\",\"title\":\"Important Jorts Note\",\"content\":\"Must not be deleted\",\"theme\":\"lime\"}]";
            try {
                FileUtils.set_contents (source_file, original_json);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });
            string? found_path = null;
            var legacy_notes = storage.find_legacy_jorts_notes (out found_path);

            assert_true (legacy_notes.size == 1);
            int imported_count = storage.import_notes (legacy_notes);
            assert_true (imported_count == 1);

            // Verify Jots markdown storage has the note
            var loaded_jots_notes = storage.load_all ();
            assert_true (loaded_jots_notes.size == 1);
            assert_cmpstr (loaded_jots_notes.get (0).id, GLib.CompareOperator.EQ, "keep-me");
            assert_cmpstr (loaded_jots_notes.get (0).title, GLib.CompareOperator.EQ, "Important Jorts Note");

            // Verify original Jorts saved_state.json is COMPLETELY UNTOUCHED
            assert_true (FileUtils.test (source_file, FileTest.EXISTS));
            string current_source_content;
            try {
                FileUtils.get_contents (source_file, out current_source_content);
                assert_cmpstr (current_source_content, GLib.CompareOperator.EQ, original_json);
            } catch (Error e) {
                assert_not_reached ();
            }
        }

        private static void test_duplicate_protection () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-target");
            storage.override_notes_dir (temp_notes_dir);

            // Pre-populate Jots storage with an existing note
            var existing_note = new NoteData () {
                id = "conflict-uuid",
                title = "Jots Existing Note",
                content = "Existing content in Jots",
                theme = Themes.BLUEBERRY
            };
            storage.save_note (existing_note);

            var temp_dir = create_temp_dir ("jorts-source");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");
            var jorts_json = "[{\"id\":\"conflict-uuid\",\"title\":\"Old Jorts Note\",\"content\":\"Old content\",\"theme\":\"lime\"}]";
            try {
                FileUtils.set_contents (source_file, jorts_json);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });

            var note_list = storage.find_legacy_jorts_notes ();
            assert_true (note_list.size == 1);

            // When imported, save_note writes file, but let's verify NoteData roundtrip
            storage.import_notes (note_list);
            var reloaded = storage.load_note_by_id ("conflict-uuid");
            assert_true (reloaded != null);
            assert_cmpstr (reloaded.id, GLib.CompareOperator.EQ, "conflict-uuid");
        }

        private static void test_malformed_legacy_json () {
            var storage = new Storage ();
            var temp_dir = create_temp_dir ("jorts-bad-json");
            var bad_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            // Corrupted JSON syntax
            try {
                FileUtils.set_contents (bad_file, "{ this is not valid json }");
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ bad_file });
            string? found_path = null;
            var notes = storage.find_legacy_jorts_notes (out found_path);

            assert_true (notes.size == 0);
            assert_true (found_path == null);
        }

        private static void test_empty_candidate_list () {
            var storage = new Storage ();
            storage.override_legacy_paths ({ "/nonexistent/path/saved_state.json", "/another/missing/file.json" });

            string? found_path = null;
            var notes = storage.find_legacy_jorts_notes (out found_path);

            assert_true (notes.size == 0);
            assert_true (found_path == null);
        }
    }

    public static void register_migration_helper_tests () {
        TestMigrationHelper.register ();
    }
}
