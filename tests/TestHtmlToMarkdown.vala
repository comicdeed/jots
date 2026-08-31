/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {

    public void register_html_to_markdown_tests () {
        /**
         * UC-30.50.10: Basic formatting, headings, and links conversion
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_10/BasicFormattingAndHeadings", () => {
            var html = "<h1>Title</h1><p>This is <b>bold</b>, <i>italic</i>, <s>strike</s>, and <a href=\"https://example.com\">a link</a>.</p>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "# Title\n\nThis is **bold**, *italic*, ~~strike~~, and [a link](https://example.com).");
        });

        /**
         * UC-30.50.20: Nested unordered and ordered lists
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_20/NestedAndOrderedLists", () => {
            var html = "<ul><li>Item 1</li><li>Item 2<ul><li>Item 2.1</li><li>Item 2.2</li></ul></li><li>Item 3</li></ul>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "- Item 1\n- Item 2\n  - Item 2.1\n  - Item 2.2\n- Item 3");

            var ol_html = "<ol><li>First</li><li>Second</li><li>Third</li></ol>";
            var ol_result = Jots.Utils.HtmlToMarkdown.convert (ol_html);
            assert_cmpstr (ol_result, GLib.CompareOperator.EQ, "1. First\n2. Second\n3. Third");
        });

        /**
         * UC-30.50.30: Inline code and preformatted code blocks
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_30/CodeAndPreBlocks", () => {
            var html = "<p>Run <code>jots --devel</code> to start.</p><pre><code>int x = 42;\nstring msg = \"hello\";</code></pre>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "Run `jots --devel` to start.\n\n```\nint x = 42;\nstring msg = \"hello\";\n```");
        });

        /**
         * UC-30.50.40: HTML tables to Markdown pipe tables
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_40/TableConversion", () => {
            var html = "<table><tr><th>Key</th><th>Value</th></tr><tr><td>Status</td><td>Active</td></tr></table>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "| Key | Value |\n| --- | --- |\n| Status | Active |");
        });

        /**
         * UC-30.50.50: Blockquotes and line breaks
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_50/BlockquotesAndBreaks", () => {
            var html = "<blockquote>First line<br>Second line</blockquote>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "> First line\n> Second line");
        });

        /**
         * UC-30.50.60: Script, style, comment removal and CSS styled spans
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_60/SanitizationAndCssSpans", () => {
            var html = "<style>body { color: red; }</style><script>alert('xss')</script><!-- comment --><p><span style=\"font-weight: bold;\">Bold span</span> and <span style=\"font-style: italic;\">Italic span</span></p>";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "**Bold span** and *Italic span*");
        });

        /**
         * UC-30.50.70: Malformed HTML graceful recovery
         */
        GLib.Test.add_func ("/HtmlToMarkdown/UC_30_50_70/MalformedHtmlRecovery", () => {
            var html = "<p><b>Unclosed bold text <a href=\"https://example.com\">unclosed link";
            var result = Jots.Utils.HtmlToMarkdown.convert (html);
            assert_cmpstr (result, GLib.CompareOperator.EQ, "**Unclosed bold text [unclosed link](https://example.com)**");
        });
    }
}
