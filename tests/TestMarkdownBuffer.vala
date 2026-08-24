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
         * UC-30.20.20: Markdown buffer highlighting runs without crashing and clears cleanly
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_20_20/SyntaxHighlighting", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "# Heading 1\n## Heading 2\n**Bold** and *Italic*\n`code` and [link](https://example.com)\n> Blockquote";
            buffer.highlight_markdown ();

            // Verify tags applied to text iter range
            Gtk.TextIter start;
            buffer.get_iter_at_line_offset (out start, 0, 2);
            assert_true (start.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));

            // Clear tags
            buffer.clear_markdown_tags ();
            assert_false (start.has_tag (buffer.tag_table.lookup (Jots.MarkdownBuffer.TAG_H1)));
        });
    }
}
