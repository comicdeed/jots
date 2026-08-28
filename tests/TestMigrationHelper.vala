/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {

    public class TestMigrationHelper {

        private static string create_temp_dir (string prefix) {
            var temp_dir = Path.build_filename (Environment.get_tmp_dir (), "%s-%s".printf (prefix, GLib.Uuid.string_random ()));
            DirUtils.create_with_parents (temp_dir, 0700);
            return temp_dir;
        }

        public static void register () {
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_10/JortsCandidateDiscovery", test_candidate_discovery);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_20/NonDestructiveImport", test_non_destructive_import);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_30/DuplicateProtection", test_duplicate_protection);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_40/MalformedLegacyJson", test_malformed_legacy_json);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_50/EmptyCandidateList", test_empty_candidate_list);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_60/ComplexContentAndEmojis", test_complex_content_and_emojis);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_70/GeometryAndZoomPreservation", test_geometry_and_zoom_preservation);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_80/BatchImportScaling", test_batch_import_scaling);
            GLib.Test.add_func ("/MigrationHelper/UC_20_50_90/MissingTitleFallback", test_missing_title_fallback);
        }

        private static void test_candidate_discovery () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-target");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir1 = create_temp_dir ("jorts-host-mock");
            var temp_dir2 = create_temp_dir ("jorts-flatpak-mock");

            var file1_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir1, "saved_state.json");
            var file2_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir2, "saved_state.json");

            // Mock JSON with 2 notes using legacy Jorts "color" integer enum schema
            var json_content1 = "[{\"id\":\"jorts-note-1\",\"title\":\"Jorts Note 1\",\"content\":\"Content 1\",\"color\":1},{\"id\":\"jorts-note-2\",\"title\":\"Jorts Note 2\",\"content\":\"Content 2\",\"color\":3}]";
            try {
                FileUtils.set_contents (file1_path, json_content1);
            } catch (Error e) {
                assert_not_reached ();
            }

            // Mock JSON with 1 note in path 2
            var json_content2 = "[{\"id\":\"jorts-note-3\",\"title\":\"Jorts Note 3\",\"content\":\"Content 3\",\"color\":0}]";
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
            assert_true (notes.get (0).theme == Themes.MINT);
            assert_cmpstr (notes.get (1).id, GLib.CompareOperator.EQ, "jorts-note-2");
            assert_true (notes.get (1).theme == Themes.BANANA);
        }

        private static void test_non_destructive_import () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-target");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-source");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            var original_json = "[{\"id\":\"keep-me\",\"title\":\"Important Jorts Note\",\"content\":\"Must not be deleted\",\"color\":2}]";
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

            // Verify Jots markdown storage has the note with correctly mapped theme
            var loaded_jots_notes = storage.load_all ();
            assert_true (loaded_jots_notes.size == 1);
            assert_cmpstr (loaded_jots_notes.get (0).id, GLib.CompareOperator.EQ, "keep-me");
            assert_cmpstr (loaded_jots_notes.get (0).title, GLib.CompareOperator.EQ, "Important Jorts Note");
            assert_true (loaded_jots_notes.get (0).theme == Themes.LIME);

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
            var jorts_json = "[{\"id\":\"conflict-uuid\",\"title\":\"Old Stale Jorts Note\",\"content\":\"Old content\",\"color\":2}]";
            try {
                FileUtils.set_contents (source_file, jorts_json);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });

            var note_list = storage.find_legacy_jorts_notes ();
            assert_true (note_list.size == 1);

            // Existing IDs are filtered before saving in NoteManager
            var existing_ids = new Gee.HashSet<string> ();
            foreach (var note in storage.load_all ()) {
                existing_ids.add (note.id);
            }

            var notes_to_import = new Gee.ArrayList<NoteData> ();
            foreach (var note in note_list) {
                if (!existing_ids.contains (note.id)) {
                    notes_to_import.add (note);
                }
            }

            assert_true (notes_to_import.size == 0);

            // Verify the existing Jots note was never overwritten
            var reloaded = storage.load_note_by_id ("conflict-uuid");
            assert_true (reloaded != null);
            assert_cmpstr (reloaded.id, GLib.CompareOperator.EQ, "conflict-uuid");
            assert_cmpstr (reloaded.title, GLib.CompareOperator.EQ, "Jots Existing Note");
            assert_cmpstr (reloaded.content, GLib.CompareOperator.EQ, "Existing content in Jots");
            assert_true (reloaded.theme == Themes.BLUEBERRY);
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

        private static void test_complex_content_and_emojis () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-complex");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-complex");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            var complex_json = "[{\"id\":\"complex-1\",\"title\":\"🚀 Plan (日本語 & Español)\",\"content\":\"# Title\\n- [ ] Task 1 ☕\\n- [x] Done ✨\\n\\n```python\\nprint(\\\"hello\\\")\\n```\",\"color\":4}]";
            try {
                FileUtils.set_contents (source_file, complex_json);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });
            var notes = storage.find_legacy_jorts_notes ();
            assert_true (notes.size == 1);

            storage.import_notes (notes);

            var reloaded = storage.load_note_by_id ("complex-1");
            assert_true (reloaded != null);
            assert_cmpstr (reloaded.title, GLib.CompareOperator.EQ, "🚀 Plan (日本語 & Español)");
            assert_true (reloaded.content.contains ("Task 1 ☕"));
            assert_true (reloaded.content.contains ("print(\"hello\")"));
            assert_true (reloaded.theme == Themes.ORANGE);
        }

        private static void test_geometry_and_zoom_preservation () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-geom");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-geom");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            // Note with custom dimensions, monospace true, and clamped zoom bounds
            var geom_json = "[{\"id\":\"geom-1\",\"title\":\"Geom Note\",\"content\":\"Code\",\"color\":0,\"monospace\":true,\"zoom\":150,\"width\":420,\"height\":550},{\"id\":\"geom-2\",\"title\":\"Clamped Note\",\"content\":\"Min zoom\",\"color\":0,\"monospace\":false,\"zoom\":5,\"width\":300,\"height\":300}]";
            try {
                FileUtils.set_contents (source_file, geom_json);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });
            var notes = storage.find_legacy_jorts_notes ();
            assert_true (notes.size == 2);

            storage.import_notes (notes);

            var note1 = storage.load_note_by_id ("geom-1");
            assert_true (note1 != null);
            assert_true (note1.monospace == true);
            assert_true (note1.zoom == 150);
            assert_true (note1.width == 420);
            assert_true (note1.height == 550);

            // Verify zoom=5 clamped to ZOOM_MIN (20)
            var note2 = storage.load_note_by_id ("geom-2");
            assert_true (note2 != null);
            assert_true (note2.zoom == ZOOM_MIN);
        }

        private static void test_batch_import_scaling () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-batch");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-batch");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            var builder = new Json.Builder ();
            builder.begin_array ();
            for (int i = 0; i < 20; i++) {
                builder.begin_object ();
                builder.set_member_name ("id");
                builder.add_string_value ("batch-note-%02d".printf (i));
                builder.set_member_name ("title");
                builder.add_string_value ("Batch Note %d".printf (i));
                builder.set_member_name ("content");
                builder.add_string_value ("Batch content for item %d".printf (i));
                builder.set_member_name ("color");
                builder.add_int_value (i % 5);
                builder.end_object ();
            }
            builder.end_array ();

            var node = builder.get_root ();
            var gen = new Json.Generator ();
            gen.set_root (node);
            try {
                gen.to_file (source_file);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });
            var notes = storage.find_legacy_jorts_notes ();
            assert_true (notes.size == 20);

            int imported = storage.import_notes (notes);
            assert_true (imported == 20);

            var all_loaded = storage.load_all ();
            assert_true (all_loaded.size == 20);
        }

        private static void test_missing_title_fallback () {
            var storage = new Storage ();
            var temp_notes_dir = create_temp_dir ("jots-notes-fallback");
            storage.override_notes_dir (temp_notes_dir);

            var temp_dir = create_temp_dir ("jorts-fallback");
            var source_file = GLib.Path.build_path (Path.DIR_SEPARATOR_S, temp_dir, "saved_state.json");

            // Note with missing title property
            var json_no_title = "[{\"id\":\"no-title-1\",\"content\":\"Body without title\",\"color\":0}]";
            try {
                FileUtils.set_contents (source_file, json_no_title);
            } catch (Error e) {
                assert_not_reached ();
            }

            storage.override_legacy_paths ({ source_file });
            var notes = storage.find_legacy_jorts_notes ();
            assert_true (notes.size == 1);
            assert_true (notes.get (0).title.length > 0);

            storage.import_notes (notes);
            var reloaded = storage.load_note_by_id ("no-title-1");
            assert_true (reloaded != null);
            assert_cmpstr (reloaded.content, GLib.CompareOperator.EQ, "Body without title");
        }
    }

    public static void register_migration_helper_tests () {
        TestMigrationHelper.register ();
    }
}
