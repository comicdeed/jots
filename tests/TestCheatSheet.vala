/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_cheatsheet_tests () {
        /**
         * UC-70.10.10: Built-in Cheat Sheet template data initialization
         */
        GLib.Test.add_func ("/CheatSheet/UC_70_10_10/TemplateCreation", () => {
            var note = new Jots.NoteData ();
            note.id = Jots.CHEATSHEET_NOTE_ID;
            note.title = Jots.CHEATSHEET_TITLE;
            note.content = Jots.CHEATSHEET_CONTENT;
            note.readonly = true;
            note.always_visible = true;

            assert_cmpstr (note.id, GLib.CompareOperator.EQ, Jots.CHEATSHEET_NOTE_ID);
            assert_cmpstr (note.title, GLib.CompareOperator.EQ, "Jots Cheat Sheet");
            assert_true (note.readonly);
            assert_true (note.always_visible);
            assert_true (note.content.contains ("# Jots Cheat Sheet"));
            assert_true (note.content.contains ("Ctrl + N"));
            assert_true (note.content.contains ("F1"));
        });

        /**
         * UC-70.10.20: YAML front matter serialization round-trip for readonly and always_visible
         */
        GLib.Test.add_func ("/CheatSheet/UC_70_10_20/YamlFrontMatterRoundTrip", () => {
            var note = new Jots.NoteData ();
            note.id = "locked-test-uuid";
            note.title = "Locked Note";
            note.content = "Read-only body content.";
            note.readonly = true;
            note.always_visible = true;

            var md = note.to_markdown ();
            assert_true (md.contains ("readonly: true"));
            assert_true (md.contains ("always_visible: true"));

            var restored = new Jots.NoteData.from_markdown (md);
            assert_cmpstr (restored.id, GLib.CompareOperator.EQ, "locked-test-uuid");
            assert_cmpstr (restored.title, GLib.CompareOperator.EQ, "Locked Note");
            assert_cmpstr (restored.content, GLib.CompareOperator.EQ, "Read-only body content.");
            assert_true (restored.readonly);
            assert_true (restored.always_visible);
        });

        /**
         * UC-70.10.30: Default values when readonly / always_visible missing from front matter
         */
        GLib.Test.add_func ("/CheatSheet/UC_70_10_30/YamlDefaultFlags", () => {
            var raw_md = "---\nid: \"legacy-123\"\ntitle: \"Legacy Note\"\n---\nHello legacy";
            var note = new Jots.NoteData.from_markdown (raw_md);

            assert_cmpstr (note.id, GLib.CompareOperator.EQ, "legacy-123");
            assert_false (note.readonly);
            assert_false (note.always_visible);
        });

        /**
         * UC-70.10.40: JSON round-trip serialization for readonly and always_visible
         */
        GLib.Test.add_func ("/CheatSheet/UC_70_10_40/JsonRoundTrip", () => {
            var note = new Jots.NoteData ();
            note.title = "JSON Protected Note";
            note.readonly = true;
            note.always_visible = true;

            var json = note.to_json ();
            var restored = new Jots.NoteData.from_json (json);

            assert_true (restored.readonly);
            assert_true (restored.always_visible);
        });
    }
}
