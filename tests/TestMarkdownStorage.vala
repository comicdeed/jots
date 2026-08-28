/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_markdown_storage_tests () {
        /**
         * UC-20.20.10: Markdown round-trip serialization with YAML front matter
         */
        GLib.Test.add_func ("/MarkdownStorage/UC_20_20_10/SerializationRoundTrip", () => {
            var note = new Jots.NoteData ();
            note.id = "test-uuid-1234";
            note.title = "Markdown Planning Note";
            note.content = "# Header\n\n- [x] Item 1\n- [ ] Item 2\n\n**Bold** and *Italic* text.";
            note.theme = Jots.Themes.BANANA;
            note.monospace = true;
            note.zoom = 140;
            note.width = 350;
            note.height = 400;

            var md = note.to_markdown ();
            var restored = new Jots.NoteData.from_markdown (md);

            assert_cmpstr (restored.id, GLib.CompareOperator.EQ, "test-uuid-1234");
            assert_cmpstr (restored.title, GLib.CompareOperator.EQ, "Markdown Planning Note");
            assert_cmpstr (restored.content, GLib.CompareOperator.EQ, "# Header\n\n- [x] Item 1\n- [ ] Item 2\n\n**Bold** and *Italic* text.");
            assert_true (restored.theme == Jots.Themes.BANANA);
            assert_true (restored.monospace == true);
            assert_cmpint (restored.zoom, GLib.CompareOperator.EQ, 140);
            assert_cmpint (restored.width, GLib.CompareOperator.EQ, 350);
            assert_cmpint (restored.height, GLib.CompareOperator.EQ, 400);
        });

        /**
         * UC-20.20.20: Plain Markdown without front matter extracts title and body
         */
        GLib.Test.add_func ("/MarkdownStorage/UC_20_20_20/PlainMarkdownFallback", () => {
            var plain_md = "# Shopping List\n\n* Apples\n* Bananas\n* Milk";
            var note = new Jots.NoteData.from_markdown (plain_md, "fallback-id-5678");

            assert_cmpstr (note.id, GLib.CompareOperator.EQ, "fallback-id-5678");
            assert_cmpstr (note.title, GLib.CompareOperator.EQ, "Shopping List");
            assert_cmpstr (note.content, GLib.CompareOperator.EQ, plain_md);
            assert_cmpint (note.zoom, GLib.CompareOperator.EQ, Jots.DEFAULT_ZOOM);
        });

        /**
         * UC-20.20.30: Corrupted or incomplete front matter gracefully handled
         */
        GLib.Test.add_func ("/MarkdownStorage/UC_20_20_30/CorruptedFrontMatter", () => {
            var corrupted = "---\nid: \"valid-id\"\nzoom: 99999\ncolor: 99\n---\nBody text";
            var note = new Jots.NoteData.from_markdown (corrupted);

            assert_cmpstr (note.id, GLib.CompareOperator.EQ, "valid-id");
            assert_cmpint (note.zoom, GLib.CompareOperator.EQ, Jots.ZOOM_MAX);
            assert_cmpstr (note.content, GLib.CompareOperator.EQ, "Body text");
        });

        /**
         * UC-20.20.40: Unicode and escaped quotes handling
         */
        GLib.Test.add_func ("/MarkdownStorage/UC_20_20_40/UnicodeAndEscapes", () => {
            var note = new Jots.NoteData ();
            note.title = "Notes with \"quotes\" & Emoji 🚀✨";
            note.content = "Multi-line unicode content: 🌟\n- Line with \"double\" and 'single' quotes.";

            var md = note.to_markdown ();
            var restored = new Jots.NoteData.from_markdown (md);

            assert_cmpstr (restored.title, GLib.CompareOperator.EQ, "Notes with \"quotes\" & Emoji 🚀✨");
            assert_cmpstr (restored.content, GLib.CompareOperator.EQ, "Multi-line unicode content: 🌟\n- Line with \"double\" and 'single' quotes.");
        });
    }
}
