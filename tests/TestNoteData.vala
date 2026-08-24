/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    public void register_note_data_tests () {
        /**
         * UC-20.10.10: Full JSON round-trip serialization
         */
        GLib.Test.add_func ("/NoteData/UC_20_10_10/SerializationRoundTrip", () => {
            var note = new Jots.NoteData ();
            note.title = "Canary Test Note";
            note.content = "Line 1: Hello!\nLine 2: Jots testing.";
            note.theme = Jots.Themes.MINT;
            note.monospace = true;
            note.zoom = 120;
            note.width = 320;
            note.height = 280;

            var json = note.to_json ();
            var restored = new Jots.NoteData.from_json (json);

            assert_cmpstr (restored.title, GLib.CompareOperator.EQ, "Canary Test Note");
            assert_cmpstr (restored.content, GLib.CompareOperator.EQ, "Line 1: Hello!\nLine 2: Jots testing.");
            assert_true (restored.theme == Jots.Themes.MINT);
            assert_true (restored.monospace == true);
            assert_cmpint (restored.zoom, GLib.CompareOperator.EQ, 120);
            assert_cmpint (restored.width, GLib.CompareOperator.EQ, 320);
            assert_cmpint (restored.height, GLib.CompareOperator.EQ, 280);
        });

        /**
         * UC-20.10.20: Corrupted or missing field fallbacks
         */
        GLib.Test.add_func ("/NoteData/UC_20_10_20/CorruptedJsonFallbacks", () => {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data ("{}");
                var empty_obj = parser.get_root ().get_object ();
                var note = new Jots.NoteData.from_json (empty_obj);

                assert_true (note.title.length > 0);
                assert_cmpstr (note.content, GLib.CompareOperator.EQ, "");
                assert_true (note.zoom >= Jots.ZOOM_MIN && note.zoom <= Jots.ZOOM_MAX);
                assert_cmpint (note.width, GLib.CompareOperator.EQ, Jots.DEFAULT_WIDTH);
                assert_cmpint (note.height, GLib.CompareOperator.EQ, Jots.DEFAULT_HEIGHT);
            } catch (GLib.Error e) {
                GLib.Test.fail ();
            }
        });

        /**
         * UC-20.10.30: Zoom value clamping
         */
        GLib.Test.add_func ("/NoteData/UC_20_10_30/ZoomClamping", () => {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data ("{\"zoom\": 9999}");
                var note_high = new Jots.NoteData.from_json (parser.get_root ().get_object ());
                assert_cmpint (note_high.zoom, GLib.CompareOperator.EQ, Jots.ZOOM_MAX);

                parser.load_from_data ("{\"zoom\": -50}");
                var note_low = new Jots.NoteData.from_json (parser.get_root ().get_object ());
                assert_cmpint (note_low.zoom, GLib.CompareOperator.EQ, Jots.ZOOM_MIN);
            } catch (GLib.Error e) {
                GLib.Test.fail ();
            }
        });

        /**
         * UC-20.10.40: UUID assignment and round-trip persistence
         */
        GLib.Test.add_func ("/NoteData/UC_20_10_40/UuidAssignmentAndPersistence", () => {
            var note = new Jots.NoteData ();
            assert_true (note.id != null && note.id.length > 0);
            assert_true (GLib.Uuid.string_is_valid (note.id));

            var original_id = note.id;
            var json = note.to_json ();
            var restored = new Jots.NoteData.from_json (json);

            assert_cmpstr (restored.id, GLib.CompareOperator.EQ, original_id);
        });

        /**
         * UC-20.10.50: Legacy JSON without UUID auto-migrates to valid UUID
         */
        GLib.Test.add_func ("/NoteData/UC_20_10_50/LegacyJsonUuidMigration", () => {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data ("{\"title\": \"Legacy Note\", \"content\": \"No UUID here\", \"color\": 0}");
                var legacy_obj = parser.get_root ().get_object ();
                var note = new Jots.NoteData.from_json (legacy_obj);

                assert_true (note.id != null && note.id.length > 0);
                assert_true (GLib.Uuid.string_is_valid (note.id));
                assert_cmpstr (note.title, GLib.CompareOperator.EQ, "Legacy Note");
            } catch (GLib.Error e) {
                GLib.Test.fail ();
            }
        });

        /**
         * UC-70.10.50: MCP Guardrail constants and limits
         */
        GLib.Test.add_func ("/NoteData/UC_70_10_50/GuardrailsAndLimits", () => {
            assert_cmpint (Jots.MAX_NOTE_CONTENT_LENGTH, GLib.CompareOperator.EQ, 10000);
            assert_cmpint (Jots.MAX_NOTE_TITLE_LENGTH, GLib.CompareOperator.EQ, 120);
            assert_cmpint (Jots.MAX_ACTIVE_NOTES, GLib.CompareOperator.EQ, 50);
            assert_cmpint (Jots.MAX_SEARCH_RESULTS, GLib.CompareOperator.EQ, 20);
        });
    }
}
