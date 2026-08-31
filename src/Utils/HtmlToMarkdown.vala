/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Utils {

    /**
     * Pure, dependency-free HTML-to-Markdown converter for clipboard and rich-text payloads.
     */
    public class HtmlToMarkdown : Object {

        private enum ListType {
            UNORDERED,
            ORDERED
        }

        private class ListState {
            public ListType list_type;
            public int index;

            public ListState (ListType type) {
                this.list_type = type;
                this.index = 1;
            }
        }

        /**
         * Converts an HTML snippet or document into clean Markdown.
         */
        public static string convert (string raw_html) {
            if (raw_html.length == 0) {
                return "";
            }

            var html = preprocess_html (raw_html);
            var sb = new StringBuilder ();

            var list_stack = new Gee.ArrayList<ListState> ();
            var link_stack = new Gee.ArrayList<string> ();

            bool in_pre = false;
            bool in_code = false;
            bool in_bold = false;
            bool in_italic = false;
            bool in_strike = false;
            int span_bold_depth = 0;
            int span_italic_depth = 0;
            int blockquote_depth = 0;
            int heading_level = 0;
            bool in_table_cell = false;
            bool in_table_header = false;
            var current_row = new Gee.ArrayList<string> ();
            var current_cell_sb = new StringBuilder ();

            int pos = 0;
            int len = html.length;

            while (pos < len) {
                int tag_start = html.index_of_char ('<', pos);
                if (tag_start < 0) {
                    // Remaining is text
                    var text_chunk = html.substring (pos);
                    append_text (sb, text_chunk, in_pre, in_table_cell ? current_cell_sb : null);
                    break;
                }

                if (tag_start > pos) {
                    var text_chunk = html.substring (pos, tag_start - pos);
                    append_text (sb, text_chunk, in_pre, in_table_cell ? current_cell_sb : null);
                }

                int tag_end = html.index_of_char ('>', tag_start);
                if (tag_end < 0) {
                    // Malformed tag, output remainder
                    var text_chunk = html.substring (tag_start);
                    append_text (sb, text_chunk, in_pre, in_table_cell ? current_cell_sb : null);
                    break;
                }

                var full_tag = html.substring (tag_start + 1, tag_end - tag_start - 1).strip ();
                pos = tag_end + 1;

                if (full_tag.length == 0) {
                    continue;
                }

                bool is_closing = full_tag.has_prefix ("/");
                var tag_content = is_closing ? full_tag.substring (1).strip () : full_tag;

                // Extract tag name
                int space_idx = tag_content.index_of_char (' ');
                var tag_name = (space_idx >= 0 ? tag_content.substring (0, space_idx) : tag_content).down ();
                var tag_attrs = space_idx >= 0 ? tag_content.substring (space_idx + 1) : "";

                // Process tag
                switch (tag_name) {
                    case "h1":
                    case "h2":
                    case "h3":
                    case "h4":
                    case "h5":
                    case "h6":
                        if (is_closing) {
                            heading_level = 0;
                            ensure_trailing_newlines (sb, 2);
                        } else {
                            ensure_trailing_newlines (sb, sb.len == 0 ? 0 : 2);
                            int level = int.parse (tag_name.substring (1));
                            heading_level = level <= 3 ? level : 3;
                            sb.append (string.nfill (heading_level, '#'));
                            sb.append_c (' ');
                        }
                        break;

                    case "b":
                    case "strong":
                        if (is_closing) {
                            if (in_bold) {
                                sb.append ("**");
                                in_bold = false;
                            }
                        } else {
                            if (!in_bold) {
                                sb.append ("**");
                                in_bold = true;
                            }
                        }
                        break;

                    case "i":
                    case "em":
                        if (is_closing) {
                            if (in_italic) {
                                sb.append ("*");
                                in_italic = false;
                            }
                        } else {
                            if (!in_italic) {
                                sb.append ("*");
                                in_italic = true;
                            }
                        }
                        break;

                    case "s":
                    case "strike":
                    case "del":
                        if (is_closing) {
                            if (in_strike) {
                                sb.append ("~~");
                                in_strike = false;
                            }
                        } else {
                            if (!in_strike) {
                                sb.append ("~~");
                                in_strike = true;
                            }
                        }
                        break;

                    case "a":
                        if (is_closing) {
                            if (link_stack.size > 0) {
                                var url = link_stack.remove_at (link_stack.size - 1);
                                sb.append ("](" + url + ")");
                            }
                        } else {
                            var url = extract_attribute (tag_attrs, "href");
                            if (url != "") {
                                link_stack.add (url);
                                sb.append_c ('[');
                            }
                        }
                        break;

                    case "ul":
                        if (is_closing) {
                            if (list_stack.size > 0) {
                                list_stack.remove_at (list_stack.size - 1);
                            }
                            if (list_stack.size == 0) {
                                ensure_trailing_newlines (sb, 1);
                            }
                        } else {
                            list_stack.add (new ListState (ListType.UNORDERED));
                        }
                        break;

                    case "ol":
                        if (is_closing) {
                            if (list_stack.size > 0) {
                                list_stack.remove_at (list_stack.size - 1);
                            }
                            if (list_stack.size == 0) {
                                ensure_trailing_newlines (sb, 1);
                            }
                        } else {
                            list_stack.add (new ListState (ListType.ORDERED));
                        }
                        break;

                    case "li":
                        if (!is_closing) {
                            ensure_trailing_newlines (sb, 1);
                            int depth = list_stack.size > 0 ? list_stack.size - 1 : 0;
                            var indent = string.nfill (depth * 2, ' ');
                            sb.append (indent);

                            if (list_stack.size > 0) {
                                var current_list = list_stack.get (list_stack.size - 1);
                                if (current_list.list_type == ListType.ORDERED) {
                                    sb.append_printf ("%d. ", current_list.index++);
                                } else {
                                    sb.append ("- ");
                                }
                            } else {
                                sb.append ("- ");
                            }
                        }
                        break;

                    case "pre":
                        if (is_closing) {
                            in_pre = false;
                            ensure_trailing_newlines (sb, 1);
                            sb.append ("```\n");
                        } else {
                            ensure_trailing_newlines (sb, sb.len == 0 ? 0 : 2);
                            sb.append ("```\n");
                            in_pre = true;
                        }
                        break;

                    case "code":
                        if (!in_pre) {
                            if (is_closing) {
                                if (in_code) {
                                    sb.append_c ('`');
                                    in_code = false;
                                }
                            } else {
                                if (!in_code) {
                                    sb.append_c ('`');
                                    in_code = true;
                                }
                            }
                        }
                        break;

                    case "blockquote":
                        if (is_closing) {
                            if (blockquote_depth > 0) blockquote_depth--;
                            ensure_trailing_newlines (sb, 1);
                        } else {
                            blockquote_depth++;
                            ensure_trailing_newlines (sb, sb.len == 0 ? 0 : 1);
                            sb.append ("> ");
                        }
                        break;

                    case "br":
                        sb.append_c ('\n');
                        if (blockquote_depth > 0) {
                            sb.append ("> ");
                        }
                        break;

                    case "p":
                    case "div":
                        if (is_closing) {
                            ensure_trailing_newlines (sb, 1);
                        } else {
                            if (sb.len > 0) {
                                ensure_trailing_newlines (sb, 1);
                            }
                            if (blockquote_depth > 0) {
                                sb.append ("> ");
                            }
                        }
                        break;

                    case "hr":
                        ensure_trailing_newlines (sb, sb.len == 0 ? 0 : 2);
                        sb.append ("---\n");
                        break;

                    case "table":
                        if (is_closing) {
                            ensure_trailing_newlines (sb, 1);
                        } else {
                            ensure_trailing_newlines (sb, sb.len == 0 ? 0 : 1);
                        }
                        break;

                    case "tr":
                        if (is_closing) {
                            if (current_row.size > 0) {
                                sb.append ("| " + string.joinv (" | ", (string[]) current_row.to_array ()) + " |\n");
                                if (in_table_header) {
                                    var separator_cells = new Gee.ArrayList<string> ();
                                    for (int col = 0; col < current_row.size; col++) {
                                        separator_cells.add ("---");
                                    }
                                    sb.append ("| " + string.joinv (" | ", (string[]) separator_cells.to_array ()) + " |\n");
                                    in_table_header = false;
                                }
                                current_row.clear ();
                            }
                        } else {
                            current_row.clear ();
                        }
                        break;

                    case "th":
                        if (is_closing) {
                            current_row.add (current_cell_sb.str.strip ());
                            current_cell_sb.truncate ();
                            in_table_cell = false;
                        } else {
                            in_table_header = true;
                            in_table_cell = true;
                            current_cell_sb.truncate ();
                        }
                        break;

                    case "td":
                        if (is_closing) {
                            current_row.add (current_cell_sb.str.strip ());
                            current_cell_sb.truncate ();
                            in_table_cell = false;
                        } else {
                            in_table_cell = true;
                            current_cell_sb.truncate ();
                        }
                        break;

                    case "img":
                        var src = extract_attribute (tag_attrs, "src");
                        var alt = extract_attribute (tag_attrs, "alt");
                        if (src != "") {
                            sb.append_printf ("![%s](%s)", alt, src);
                        }
                        break;

                    case "span":
                        if (is_closing) {
                            if (span_bold_depth > 0) {
                                sb.append ("**");
                                span_bold_depth--;
                            }
                            if (span_italic_depth > 0) {
                                sb.append ("*");
                                span_italic_depth--;
                            }
                        } else {
                            var lower_attrs = tag_attrs.down ();
                            if (lower_attrs.contains ("font-weight:") && (lower_attrs.contains ("bold") || lower_attrs.contains ("700") || lower_attrs.contains ("800") || lower_attrs.contains ("900"))) {
                                sb.append ("**");
                                span_bold_depth++;
                            }
                            if (lower_attrs.contains ("font-style:") && lower_attrs.contains ("italic")) {
                                sb.append ("*");
                                span_italic_depth++;
                            }
                        }
                        break;
                }
            }

            // Close any unclosed links and formatting
            while (link_stack.size > 0) {
                var url = link_stack.remove_at (link_stack.size - 1);
                sb.append ("](" + url + ")");
            }
            if (in_bold || span_bold_depth > 0) sb.append ("**");
            if (in_italic || span_italic_depth > 0) sb.append ("*");
            if (in_strike) sb.append ("~~");
            if (in_code) sb.append_c ('`');
            if (in_pre) sb.append ("\n```");

            return sb.str.strip ();
        }

        private static void append_text (StringBuilder main_sb, string text, bool in_pre, StringBuilder? cell_sb) {
            var decoded = MarkdownNormalizer.unescape_entities (text);
            var content = in_pre ? decoded : collapse_whitespace (decoded);

            if (cell_sb != null) {
                cell_sb.append (content);
            } else {
                main_sb.append (content);
            }
        }

        private static string collapse_whitespace (string text) {
            // Replace multiple spaces and newlines with a single space if not in <pre>
            var sb = new StringBuilder ();
            bool last_was_space = false;

            for (int i = 0; i < text.length; i++) {
                char c = text[i];
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                    if (!last_was_space) {
                        sb.append_c (' ');
                        last_was_space = true;
                    }
                } else {
                    sb.append_c (c);
                    last_was_space = false;
                }
            }

            return sb.str;
        }

        private static void ensure_trailing_newlines (StringBuilder sb, int count) {
            if (sb.len == 0) {
                return;
            }

            int existing_newlines = 0;
            int idx = (int) sb.len - 1;
            while (idx >= 0 && sb.str[idx] == '\n') {
                existing_newlines++;
                idx--;
            }

            for (int i = existing_newlines; i < count; i++) {
                sb.append_c ('\n');
            }
        }

        private static GLib.Regex? regex_style;
        private static GLib.Regex? regex_script;
        private static GLib.Regex? regex_head;
        private static GLib.Regex? regex_comments;

        private static void ensure_initialized () {
            if (regex_style != null) return;
            try {
                regex_style = new GLib.Regex ("<style[^>]*>[\\s\\S]*?</style>", GLib.RegexCompileFlags.CASELESS);
                regex_script = new GLib.Regex ("<script[^>]*>[\\s\\S]*?</script>", GLib.RegexCompileFlags.CASELESS);
                regex_head = new GLib.Regex ("<head[^>]*>[\\s\\S]*?</head>", GLib.RegexCompileFlags.CASELESS);
                regex_comments = new GLib.Regex ("<!--[\\s\\S]*?-->");
            } catch (GLib.Error e) {
                warning ("Failed to compile HtmlToMarkdown regexes: %s", e.message);
            }
        }

        private static string extract_attribute (string attrs_str, string attr_name) {
            var lower_attrs = attrs_str.down ();
            var needle = attr_name.down () + "=";
            int idx = lower_attrs.index_of (needle);
            while (idx >= 0) {
                if (idx == 0 || lower_attrs[idx - 1] == ' ' || lower_attrs[idx - 1] == '\t' || lower_attrs[idx - 1] == '\n') {
                    break;
                }
                idx = lower_attrs.index_of (needle, idx + needle.length);
            }
            if (idx < 0) {
                return "";
            }

            int val_start = idx + needle.length;
            if (val_start >= attrs_str.length) {
                return "";
            }

            char quote = attrs_str[val_start];
            if (quote == '"' || quote == '\'') {
                val_start++;
                int val_end = attrs_str.index_of_char (quote, val_start);
                if (val_end >= 0) {
                    return attrs_str.substring (val_start, val_end - val_start).strip ();
                }
            } else {
                int val_end = attrs_str.index_of_char (' ', val_start);
                if (val_end >= 0) {
                    return attrs_str.substring (val_start, val_end - val_start).strip ();
                } else {
                    return attrs_str.substring (val_start).strip ();
                }
            }

            return "";
        }

        private static string preprocess_html (string raw_html) {
            ensure_initialized ();
            var text = raw_html;

            // Strip style, script, head, and comments
            try {
                if (regex_style != null) text = regex_style.replace_literal (text, -1, 0, "");
                if (regex_script != null) text = regex_script.replace_literal (text, -1, 0, "");
                if (regex_head != null) text = regex_head.replace_literal (text, -1, 0, "");
                if (regex_comments != null) text = regex_comments.replace_literal (text, -1, 0, "");
            } catch (GLib.Error e) {
                warning ("HTML preprocessing regex error: %s", e.message);
            }

            return text;
        }
    }
}
