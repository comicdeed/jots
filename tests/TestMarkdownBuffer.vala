/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    public void register_markdown_buffer_tests () {
        /**
         * UC-30.20.10: Markdown list prefix detection
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_10/ListPrefixDetection", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "- Standard item\n* Star item\n- [ ] Todo item\n- [x] Done item\nNot a list item";

            assert_cmpstr (buffer.get_list_prefix (0), GLib.CompareOperator.EQ, "- ");
            assert_cmpstr (buffer.get_list_prefix (1), GLib.CompareOperator.EQ, "* ");
            assert_cmpstr (buffer.get_list_prefix (2), GLib.CompareOperator.EQ, "- [ ] ");
            assert_cmpstr (buffer.get_list_prefix (3), GLib.CompareOperator.EQ, "- [ ] ");
            assert_null (buffer.get_list_prefix (4));
        });

        /**
         * UC-30.20.20: Headings H1, H2, H3 and syntax prefix dimming
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_20/HeadingsScaleAndSyntax", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "# Heading 1\n## Heading 2\n### Heading 3";
            buffer.highlight_markdown ();

            // H1 text and syntax marker
            Gtk.TextIter h1_marker, h1_text;
            buffer.get_iter_at_line_offset (out h1_marker, 0, 0); // "#"
            buffer.get_iter_at_line_offset (out h1_text, 0, 3);   // "Heading 1"
            assert_true (h1_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (h1_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));

            // H2 text and syntax marker
            Gtk.TextIter h2_marker, h2_text;
            buffer.get_iter_at_line_offset (out h2_marker, 1, 0); // "##"
            buffer.get_iter_at_line_offset (out h2_text, 1, 4);   // "Heading 2"
            assert_true (h2_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (h2_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H2)));

            // H3 text and syntax marker
            Gtk.TextIter h3_marker, h3_text;
            buffer.get_iter_at_line_offset (out h3_marker, 2, 0); // "###"
            buffer.get_iter_at_line_offset (out h3_text, 2, 5);   // "Heading 3"
            assert_true (h3_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (h3_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H3)));
        });

        /**
         * UC-30.20.30: Inline emphasis (bold, italic, strikethrough) and delimiter-scoped syntax tagging
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_30/InlineEmphasisAndDelimiters", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "**bold** and *italic* and ~~strike~~";
            buffer.highlight_markdown ();

            // Bold content vs delimiter
            Gtk.TextIter bold_delim, bold_content;
            buffer.get_iter_at_line_offset (out bold_delim, 0, 0); // "**"
            buffer.get_iter_at_line_offset (out bold_content, 0, 3); // "bold"
            assert_true (bold_delim.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (bold_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_BOLD)));
            assert_false (bold_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));

            // Italic content vs delimiter
            Gtk.TextIter italic_delim, italic_content;
            buffer.get_iter_at_line_offset (out italic_delim, 0, 13); // "*"
            buffer.get_iter_at_line_offset (out italic_content, 0, 15); // "italic"
            assert_true (italic_delim.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (italic_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_ITALIC)));
            assert_false (italic_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));

            // Strikethrough content vs delimiter
            Gtk.TextIter strike_delim, strike_content;
            buffer.get_iter_at_line_offset (out strike_delim, 0, 26); // "~~"
            buffer.get_iter_at_line_offset (out strike_content, 0, 29); // "strike"
            assert_true (strike_delim.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (strike_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_STRIKETHROUGH)));
            assert_false (strike_content.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
        });

        /**
         * UC-30.20.40: Inline code (`code`) monospace tag and background
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_40/InlineCodeAndMonospace", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "Run `npm start` now";
            buffer.highlight_markdown ();

            var code_tag = buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_CODE);
            assert_true (code_tag != null);

            Gtk.TextIter delim_iter, code_iter;
            buffer.get_iter_at_line_offset (out delim_iter, 0, 4); // "`"
            buffer.get_iter_at_line_offset (out code_iter, 0, 6);  // "npm"

            assert_true (delim_iter.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (code_iter.has_tag (code_tag));
            assert_false (code_iter.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
        });

        /**
         * UC-30.20.50: Triple-backtick multiline code fence highlighting
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_50/CodeBlockHighlighting", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "Header\n```vala\nvar x = 42;\n```\nFooter";
            buffer.highlight_markdown ();

            Gtk.TextIter code_iter;
            buffer.get_iter_at_line_offset (out code_iter, 2, 2); // on "var x = 42;" line
            assert_true (code_iter.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_CODE_BLOCK)));

            Gtk.TextIter fence_iter;
            buffer.get_iter_at_line_offset (out fence_iter, 1, 0); // on "```vala" line
            assert_true (fence_iter.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
        });

        /**
         * UC-30.20.60: Checklists and completed task strikethrough
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_60/ChecklistsAndTasks", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "- [ ] Todo task\n- [x] Completed task";
            buffer.highlight_markdown ();

            // Pending task
            Gtk.TextIter todo_marker, todo_text;
            buffer.get_iter_at_line_offset (out todo_marker, 0, 0);
            buffer.get_iter_at_line_offset (out todo_text, 0, 7);
            assert_true (todo_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_false (todo_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_TASK_DONE)));

            // Done task
            Gtk.TextIter done_marker, done_text;
            buffer.get_iter_at_line_offset (out done_marker, 1, 0);
            buffer.get_iter_at_line_offset (out done_text, 1, 7);
            assert_true (done_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (done_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_TASK_DONE)));
        });

        /**
         * UC-30.20.70: Blockquotes and Links
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_70/BlockquotesAndLinks", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "> Important wisdom\nVisit [GNOME](https://gnome.org)";
            buffer.highlight_markdown ();

            // Quote
            Gtk.TextIter quote_marker, quote_text;
            buffer.get_iter_at_line_offset (out quote_marker, 0, 0);
            buffer.get_iter_at_line_offset (out quote_text, 0, 3);
            assert_true (quote_marker.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_SYNTAX)));
            assert_true (quote_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_QUOTE)));

            // Link
            Gtk.TextIter link_text;
            buffer.get_iter_at_line_offset (out link_text, 1, 8); // "GNOME"
            assert_true (link_text.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_LINK)));
        });

        /**
         * UC-30.20.80: Tag cleanup and re-highlight lifecycle
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_80/ClearAndRehighlightLifecycle", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "# Title\n**bold**";
            buffer.highlight_markdown ();

            Gtk.TextIter start;
            buffer.get_iter_at_line_offset (out start, 0, 2);
            assert_true (start.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));

            buffer.clear_markdown_tags ();
            assert_false (start.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));

            buffer.highlight_markdown ();
            assert_true (start.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));
        });

        /**
         * UC-30.20.90: Code tag family release and restoration for scribbly obfuscation
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_90/ScribblyCodeObfuscationToggle", () => {
            var buffer = new Jots.MarkdownBuffer ();
            var code_tag = buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_CODE);
            var block_tag = buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_CODE_BLOCK);

            assert_true (code_tag.family_set);
            assert_true (block_tag.family_set);

            // Obfuscate (scribbled)
            buffer.set_scribbled (true);
            assert_false (code_tag.family_set);
            assert_false (block_tag.family_set);

            // Restore
            buffer.set_scribbled (false);
            assert_true (code_tag.family_set);
            assert_true (block_tag.family_set);
        });
    }
}
