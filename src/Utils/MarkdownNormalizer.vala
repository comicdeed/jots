/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Utils {

    /**
     * Pure stateless utility for normalizing loose, non-standard, or imprecise Markdown text.
     */
    public class MarkdownNormalizer : Object {

        private static GLib.Regex? regex_crlf;
        private static GLib.Regex? regex_unicode_bullets;
        private static GLib.Regex? regex_standard_lists;
        private static GLib.Regex? regex_loose_tasks;
        private static GLib.Regex? regex_unicode_tasks;
        private static GLib.Regex? regex_headings;

        private static void ensure_initialized () {
            if (regex_crlf != null) return;
            try {
                regex_crlf = new GLib.Regex ("\\r\\n|\\r");
                // Matches non-standard Unicode bullet characters
                regex_unicode_bullets = new GLib.Regex ("^(\\s*)(•|◦|▪|▫|⁃|‣|∙|–|—|·)\\s*", GLib.RegexCompileFlags.MULTILINE);
                // Matches indented standard Markdown list items to align indentation
                regex_standard_lists = new GLib.Regex ("^([ \\t]+)([\\*\\+-]|\\d+\\.)\\s+", GLib.RegexCompileFlags.MULTILINE);
                // Matches loose task markers without preceding hyphens or non-standard brackets
                regex_loose_tasks = new GLib.Regex ("^(\\s*)\\[([xXvV\\s])\\]\\s+", GLib.RegexCompileFlags.MULTILINE);
                // Matches unicode checkbox glyphs (including optional variation selectors like \uFE0F)
                regex_unicode_tasks = new GLib.Regex ("^(\\s*)(☐|☑|☒|✅|✔️|✔|❌)(?:\\x{FE0F})?\\s*", GLib.RegexCompileFlags.MULTILINE);
                // Matches headings lacking space after '#' (1 to 3 '#'), avoiding hex colors (#fff, #123)
                regex_headings = new GLib.Regex ("^(#{1,3})([^\\s#\\d][^\\n]*)$", GLib.RegexCompileFlags.MULTILINE);
            } catch (GLib.Error e) {
                warning ("Failed to compile MarkdownNormalizer regexes: %s", e.message);
            }
        }

        /**
         * Normalizes raw input text into clean, standard Markdown.
         */
        public static string normalize (string input) {
            if (input.length == 0) {
                return input;
            }

            ensure_initialized ();

            var text = input;

            // 1. Line endings: CRLF / CR -> LF
            if (regex_crlf != null) {
                try {
                    text = regex_crlf.replace_literal (text, -1, 0, "\n");
                } catch (GLib.Error e) {}
            }

            // 2. Expand hard tabs to 2 spaces
            text = expand_tabs (text);

            // 3. Dedent common leading whitespace across all lines
            text = dedent (text);

            // 4. Normalize Unicode checkboxes (☐, ☑, etc.)
            if (regex_unicode_tasks != null) {
                try {
                    text = regex_unicode_tasks.replace_eval (text, -1, 0, 0, (info, res) => {
                        var indent = normalize_indent (info.fetch (1));
                        var glyph = info.fetch (2);
                        bool is_checked = (glyph.has_prefix ("☑") || glyph.has_prefix ("☒") || glyph.has_prefix ("✅") || glyph.has_prefix ("✔️") || glyph.has_prefix ("✔"));
                        res.append_printf ("%s- [%s] ", indent, is_checked ? "x" : " ");
                        return false;
                    });
                } catch (GLib.Error e) {}
            }

            // 5. Normalize loose task checkboxes ([ ], [x], [X], [v]) lacking bullet prefixes
            if (regex_loose_tasks != null) {
                try {
                    text = regex_loose_tasks.replace_eval (text, -1, 0, 0, (info, res) => {
                        var indent = normalize_indent (info.fetch (1));
                        var state = info.fetch (2).strip ();
                        bool is_checked = (state == "x" || state == "X" || state == "v" || state == "V");
                        res.append_printf ("%s- [%s] ", indent, is_checked ? "x" : " ");
                        return false;
                    });
                } catch (GLib.Error e) {}
            }

            // 6. Normalize non-standard Unicode bullet characters to standard "- "
            if (regex_unicode_bullets != null) {
                try {
                    text = regex_unicode_bullets.replace_eval (text, -1, 0, 0, (info, res) => {
                        var indent = normalize_indent (info.fetch (1));
                        res.append_printf ("%s- ", indent);
                        return false;
                    });
                } catch (GLib.Error e) {}
            }

            // 7. Align indentation on indented standard lists while preserving the user's chosen marker (*, +, -, 1.)
            if (regex_standard_lists != null) {
                try {
                    text = regex_standard_lists.replace_eval (text, -1, 0, 0, (info, res) => {
                        var indent = normalize_indent (info.fetch (1));
                        var marker = info.fetch (2);
                        res.append_printf ("%s%s ", indent, marker);
                        return false;
                    });
                } catch (GLib.Error e) {}
            }

            // 8. Harmonize mixed list markers by adopting the first marker encountered for each indentation level
            text = harmonize_list_markers (text);

            // 9. Normalize headings lacking space (e.g. "#Heading" -> "# Heading")
            if (regex_headings != null) {
                try {
                    text = regex_headings.replace_eval (text, -1, 0, 0, (info, res) => {
                        var hashes = info.fetch (1);
                        var heading_text = info.fetch (2);
                        res.append_printf ("%s %s", hashes, heading_text);
                        return false;
                    });
                } catch (GLib.Error e) {}
            }

            // 10. Unescape common HTML entities
            text = unescape_entities (text);

            return text;
        }

        /**
         * Harmonizes mixed bullet markers (*, -, +) within the same list block by adopting
         * the first marker style encountered for each indentation level.
         */
        public static string harmonize_list_markers (string text) {
            var lines = text.split ("\n");
            var level_markers = new Gee.HashMap<int, string> ();
            var sb = new StringBuilder ();

            for (int i = 0; i < lines.length; i++) {
                var line = lines[i];
                var trimmed = line.strip ();

                // Blank line, heading, or code fence resets the active list block marker memory
                if (trimmed.length == 0 || trimmed.has_prefix ("#") || trimmed.has_prefix ("```")) {
                    level_markers.clear ();
                    sb.append (line);
                    if (i < lines.length - 1) sb.append_c ('\n');
                    continue;
                }

                int indent_len = 0;
                while (indent_len < line.length && line[indent_len] == ' ') {
                    indent_len++;
                }

                var after_indent = line.substring (indent_len);
                // Check if it's an unordered bullet (and not a task item)
                if ((after_indent.has_prefix ("* ") || after_indent.has_prefix ("- ") || after_indent.has_prefix ("+ ")) &&
                    !after_indent.has_prefix ("* [") && !after_indent.has_prefix ("- [") && !after_indent.has_prefix ("+ [")) {

                    var marker = after_indent.substring (0, 2);
                    var content = after_indent.substring (2);
                    int level = indent_len;

                    if (!level_markers.has_key (level)) {
                        level_markers[level] = marker;
                    }

                    var chosen_marker = level_markers[level];
                    sb.append (line.substring (0, indent_len));
                    sb.append (chosen_marker);
                    sb.append (content);
                    if (i < lines.length - 1) sb.append_c ('\n');
                    continue;
                }

                sb.append (line);
                if (i < lines.length - 1) sb.append_c ('\n');
            }

            return sb.str;
        }

        /**
         * Strips common leading whitespace from a multi-line string.
         */
        public static string dedent (string text) {
            var lines = text.split ("\n");
            if (lines.length <= 1) {
                return text;
            }

            int min_indent = -1;
            foreach (var line in lines) {
                if (line.strip ().length == 0) {
                    continue;
                }
                int spaces = 0;
                while (spaces < line.length && line[spaces] == ' ') {
                    spaces++;
                }
                if (min_indent == -1 || spaces < min_indent) {
                    min_indent = spaces;
                }
            }

            if (min_indent <= 0) {
                return text;
            }

            var sb = new StringBuilder ();
            for (int idx = 0; idx < lines.length; idx++) {
                var line = lines[idx];
                if (line.length >= min_indent) {
                    sb.append (line.substring (min_indent));
                } else {
                    sb.append (line);
                }
                if (idx < lines.length - 1) {
                    sb.append_c ('\n');
                }
            }
            return sb.str;
        }

        /**
         * Normalizes list indentation to clean 2-space increments (e.g., 1 or 3 spaces -> 2 spaces).
         */
        public static string normalize_indent (string indent_str) {
            int len = indent_str.length;
            if (len == 0) {
                return "";
            }
            // Round to nearest 2-space multiple
            int rounded = ((len + 1) / 2) * 2;
            if (rounded == 0) rounded = 2;
            return string.nfill (rounded, ' ');
        }

        public static string expand_tabs (string text, int tab_width = 2) {
            if (!text.contains ("\t")) {
                return text;
            }
            var spaces = string.nfill (tab_width, ' ');
            return text.replace ("\t", spaces);
        }

        public static string unescape_entities (string text) {
            if (!text.contains ("&")) {
                return text;
            }

            return text
                .replace ("&amp;", "&")
                .replace ("&lt;", "<")
                .replace ("&gt;", ">")
                .replace ("&quot;", "\"")
                .replace ("&apos;", "'")
                .replace ("&#39;", "'")
                .replace ("&nbsp;", " ")
                .replace ("&mdash;", "—")
                .replace ("&ndash;", "–");
        }
    }
}
