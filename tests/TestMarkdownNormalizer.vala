/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {

    public void register_markdown_normalizer_tests () {
        /**
         * UC-30.30.10: Unicode bullet normalization to standard hyphens
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_10/UnicodeBulletNormalization", () => {
            var input = "• Bullet one\n◦ Bullet two\n▪ Bullet three\n  ▫ Indented bullet\n⁃ Hyphen bullet\n‣ Triangular bullet\n– En dash bullet\n— Em dash bullet\n· Middle dot bullet";
            var expected = "- Bullet one\n- Bullet two\n- Bullet three\n  - Indented bullet\n- Hyphen bullet\n- Triangular bullet\n- En dash bullet\n- Em dash bullet\n- Middle dot bullet";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.20: Checklist and task marker normalization
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_20/TaskMarkerNormalization", () => {
            var input = "[ ] Pending task\n[x] Done task\n[X] Done task uppercase\n[v] Check task\n  [ ] Indented task\n☐ Unicode pending\n☑ Unicode done\n✅ Emoji done\n✔️ Emoji check done";
            var expected = "- [ ] Pending task\n- [x] Done task\n- [x] Done task uppercase\n- [x] Check task\n  - [ ] Indented task\n- [ ] Unicode pending\n- [x] Unicode done\n- [x] Emoji done\n- [x] Emoji check done";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.30: Heading space normalization without corrupting hex colors or hashtags
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_30/HeadingNormalizationAndSafeguards", () => {
            var input = "#Heading 1\n##Heading 2\n###Heading 3\nColor #ffffff and #3b82f6\nIssue #123 and tag #feature\n[Link](#anchor-target)";
            var expected = "# Heading 1\n## Heading 2\n### Heading 3\nColor #ffffff and #3b82f6\nIssue #123 and tag #feature\n[Link](#anchor-target)";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.40: CRLF to LF normalization and tab character expansion
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_40/CrlfAndTabExpansion", () => {
            var input = "Line 1\r\nLine 2\r\n\t- Indented with tab\r\n\t\t- Sub-item";
            var expected = "Line 1\nLine 2\n  - Indented with tab\n    - Sub-item";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.50: HTML entity unescaping for pasted text
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_50/HtmlEntityUnescaping", () => {
            var input = "Tom &amp; Jerry &lt;script&gt; &quot;quoted&quot; &#39;single&#39; non&nbsp;breaking &mdash; dash";
            var expected = "Tom & Jerry <script> \"quoted\" 'single' non breaking — dash";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.60: Idempotency on already standard Markdown
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_60/IdempotencyGuarantee", () => {
            var standard_md = "# Title\n\n- Item 1\n- Item 2\n- [ ] Todo item\n- [x] Done item\n\n```vala\nvar x = 42;\n```\n";
            var result = Jots.Utils.MarkdownNormalizer.normalize (standard_md);
            assert_cmpstr (result, GLib.CompareOperator.EQ, standard_md);
        });

        /**
         * UC-30.30.70: Code context detection in MarkdownBuffer
         */
        GLib.Test.add_func ("/MarkdownBuffer/UC_30_30_70/CodeContextDetection", () => {
            var buffer = new Jots.MarkdownBuffer ();
            buffer.text = "# Title\n```vala\nvar greeting = \"hello\";\n```\nRegular `inline code` text";
            buffer.highlight_markdown ();

            // Outside code: line 0 ("# Title")
            Gtk.TextIter iter_title;
            buffer.get_iter_at_line_offset (out iter_title, 0, 2);
            assert_false (buffer.is_code_context (iter_title));

            // Inside code block: line 2 ("var greeting = ...")
            Gtk.TextIter iter_block;
            buffer.get_iter_at_line_offset (out iter_block, 2, 4);
            assert_true (buffer.is_code_context (iter_block));

            // Inside inline code: line 4 inside `inline code`
            Gtk.TextIter iter_inline;
            buffer.get_iter_at_line_offset (out iter_inline, 4, 12);
            assert_true (buffer.is_code_context (iter_inline));

            // Outside inline code: line 4 on "Regular"
            Gtk.TextIter iter_regular;
            buffer.get_iter_at_line_offset (out iter_regular, 4, 2);
            assert_false (buffer.is_code_context (iter_regular));
        });

        /**
         * UC-30.30.80: Dedent and indented nested list normalization with marker preservation
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_80/DedentAndNestedListNormalization", () => {
            var input = " * Item 1\n * Item 2\n   * Item 2.1\n   * Item 2.2\n   * Item 2.3\n   * Item 2.4\n * Item 3";
            var expected = "* Item 1\n* Item 2\n  * Item 2.1\n  * Item 2.2\n  * Item 2.3\n  * Item 2.4\n* Item 3";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });

        /**
         * UC-30.30.90: Harmonize mixed list markers by adopting the first marker for each indentation level
         */
        GLib.Test.add_func ("/MarkdownNormalizer/UC_30_30_90/HarmonizeMixedListMarkersPerLevel", () => {
            var input = "* Item 1\n- Item 2\n+ Item 3\n  - Sub A\n  * Sub B\n  + Sub C";
            var expected = "* Item 1\n* Item 2\n* Item 3\n  - Sub A\n  - Sub B\n  - Sub C";
            var result = Jots.Utils.MarkdownNormalizer.normalize (input);
            assert_cmpstr (result, GLib.CompareOperator.EQ, expected);
        });
    }
}
