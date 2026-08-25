/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

namespace Jots {

    /**
     * TextBuffer subclass that provides real-time, native Markdown syntax tagging and styling.
     */
    public class MarkdownBuffer : Gtk.TextBuffer {

        public const string TAG_H1 = "md_h1";
        public const string TAG_H2 = "md_h2";
        public const string TAG_H3 = "md_h3";
        public const string TAG_BOLD = "md_bold";
        public const string TAG_ITALIC = "md_italic";
        public const string TAG_STRIKETHROUGH = "md_strikethrough";
        public const string TAG_CODE = "md_code";
        public const string TAG_CODE_BLOCK = "md_code_block";
        public const string TAG_QUOTE = "md_quote";
        public const string TAG_TASK_DONE = "md_task_done";
        public const string TAG_SYNTAX = "md_syntax";
        public const string TAG_LINK = "md_link";
        public const string TAG_LIST = "md_list";

        private uint highlight_timeout_id = 0;
        private bool is_highlighting = false;

        // Compiled regular expressions for fast matching
        private GLib.Regex? regex_h1;
        private GLib.Regex? regex_h2;
        private GLib.Regex? regex_h3;
        private GLib.Regex? regex_bold;
        private GLib.Regex? regex_italic;
        private GLib.Regex? regex_strike;
        private GLib.Regex? regex_code;
        private GLib.Regex? regex_code_block;
        private GLib.Regex? regex_quote;
        private GLib.Regex? regex_task_done;
        private GLib.Regex? regex_task_todo;
        private GLib.Regex? regex_list;
        private GLib.Regex? regex_link;
        private GLib.Settings? settings;

        construct {
            setup_tags ();
            init_regexes ();

            changed.connect (on_buffer_changed);

            if (GLib.SettingsSchemaSource.get_default () != null) {
                try {
                    var schema_source = GLib.SettingsSchemaSource.get_default ();
                    if (schema_source != null && schema_source.lookup (APP_ID, true) != null) {
                        settings = new GLib.Settings (APP_ID);
                        settings.changed[KEY_CUSTOM_FONTS].connect (refresh_code_tag_fonts);
                        settings.changed[KEY_MONOSPACE_FONT].connect (refresh_code_tag_fonts);
                    }
                } catch (GLib.Error e) {}
            }
        }

        private void setup_tags () {
            create_tag (TAG_H1,
                "scale", 1.35,
                "weight", Pango.Weight.BOLD
            );

            create_tag (TAG_H2,
                "scale", 1.20,
                "weight", Pango.Weight.BOLD
            );

            create_tag (TAG_H3,
                "scale", 1.10,
                "weight", Pango.Weight.BOLD
            );

            create_tag (TAG_BOLD,
                "weight", Pango.Weight.BOLD
            );

            create_tag (TAG_ITALIC,
                "style", Pango.Style.ITALIC
            );

            create_tag (TAG_STRIKETHROUGH,
                "strikethrough", true
            );

            var mono_family = FontController.get_active_monospace_family ();

            create_tag (TAG_CODE,
                "family", mono_family,
                "family-set", true,
                "background-rgba", Gdk.RGBA () { red = 0.5f, green = 0.5f, blue = 0.5f, alpha = 0.15f }
            );

            create_tag (TAG_CODE_BLOCK,
                "family", mono_family,
                "family-set", true,
                "left-margin", 12,
                "right-margin", 12,
                "background-rgba", Gdk.RGBA () { red = 0.5f, green = 0.5f, blue = 0.5f, alpha = 0.12f }
            );

            create_tag (TAG_QUOTE,
                "style", Pango.Style.ITALIC,
                "left-margin", 16
            );

            create_tag (TAG_TASK_DONE,
                "strikethrough", true
            );

            create_tag (TAG_SYNTAX,
                "foreground-rgba", Gdk.RGBA () { red = 0.5f, green = 0.5f, blue = 0.5f, alpha = 0.65f }
            );

            create_tag (TAG_LINK,
                "underline", Pango.Underline.SINGLE
            );

            create_tag (TAG_LIST,
                "accumulative-margin", true,
                "left-margin", 16,
                "indent", -16
            );
        }

        public void set_scribbled (bool is_scribbled) {
            var code_tag = tag_table.lookup (TAG_CODE);
            var block_tag = tag_table.lookup (TAG_CODE_BLOCK);

            if (is_scribbled) {
                if (code_tag != null) {
                    code_tag.family_set = false;
                }
                if (block_tag != null) {
                    block_tag.family_set = false;
                }
            } else {
                var mono_family = FontController.get_active_monospace_family ();
                if (code_tag != null) {
                    code_tag.family = mono_family;
                    code_tag.family_set = true;
                }
                if (block_tag != null) {
                    block_tag.family = mono_family;
                    block_tag.family_set = true;
                }
            }
        }

        private void refresh_code_tag_fonts () {
            var mono_family = FontController.get_active_monospace_family ();
            var code_tag = tag_table.lookup (TAG_CODE);
            if (code_tag != null) {
                code_tag.family = mono_family;
                code_tag.family_set = true;
            }
            var block_tag = tag_table.lookup (TAG_CODE_BLOCK);
            if (block_tag != null) {
                block_tag.family = mono_family;
                block_tag.family_set = true;
            }
            highlight_markdown ();
        }

        private void init_regexes () {
            try {
                regex_h1 = new GLib.Regex ("^# (.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_h2 = new GLib.Regex ("^## (.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_h3 = new GLib.Regex ("^### (.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_bold = new GLib.Regex ("(\\*\\*|__)(.+?)\\1");
                regex_italic = new GLib.Regex ("(?<!\\*|_)(\\*|_)(.+?)(?<!\\*|_)\\1");
                regex_strike = new GLib.Regex ("(~~)(.+?)\\1");
                regex_code = new GLib.Regex ("(`)([^`\n]+?)\\1");
                regex_code_block = new GLib.Regex ("(```[a-zA-Z0-9_-]*\\n?)([\\s\\S]*?)(```)", GLib.RegexCompileFlags.DOTALL);
                regex_quote = new GLib.Regex ("^> (.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_task_done = new GLib.Regex ("^([\\*\\+-]\\s+\\[[xX]\\]\\s+)(.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_task_todo = new GLib.Regex ("^([\\*\\+-]\\s+\\[ \\]\\s+)(.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_list = new GLib.Regex ("^([\\*\\+-]|\\d+\\.)\\s+(.+)$", GLib.RegexCompileFlags.MULTILINE);
                regex_link = new GLib.Regex ("\\[([^\\]]+)\\]\\(([^\\)]+)\\)");
            } catch (GLib.Error e) {
                warning ("Failed to compile Markdown regex: %s", e.message);
            }
        }

        private void on_buffer_changed () {
            if (is_highlighting) {
                return;
            }

            if (highlight_timeout_id != 0) {
                GLib.Source.remove (highlight_timeout_id);
            }

            highlight_timeout_id = Timeout.add (50, highlight_handler);
        }

        private bool highlight_handler () {
            highlight_timeout_id = 0;
            highlight_markdown ();
            return GLib.Source.REMOVE;
        }

        /**
         * Clears all Markdown styling tags across the entire buffer.
         */
        public void clear_markdown_tags () {
            Gtk.TextIter start, end;
            get_bounds (out start, out end);

            string[] tags = {
                TAG_H1, TAG_H2, TAG_H3, TAG_BOLD, TAG_ITALIC,
                TAG_STRIKETHROUGH, TAG_CODE, TAG_CODE_BLOCK,
                TAG_QUOTE, TAG_TASK_DONE, TAG_SYNTAX, TAG_LINK, TAG_LIST
            };

            foreach (var tag_name in tags) {
                remove_tag_by_name (tag_name, start, end);
            }
        }

        /**
         * Parses the entire buffer text and applies appropriate GtkTextTags.
         */
        public void highlight_markdown () {
            if (is_highlighting) {
                return;
            }

            is_highlighting = true;
            clear_markdown_tags ();

            Gtk.TextIter buffer_start, buffer_end;
            get_bounds (out buffer_start, out buffer_end);
            var text = get_text (buffer_start, buffer_end, false);

            if (text.length == 0) {
                is_highlighting = false;
                return;
            }

            // Headings H1, H2, H3
            apply_regex_line_match (regex_h1, text, TAG_H1, 2);
            apply_regex_line_match (regex_h2, text, TAG_H2, 3);
            apply_regex_line_match (regex_h3, text, TAG_H3, 4);

            // Blockquotes
            apply_regex_line_match (regex_quote, text, TAG_QUOTE, 2);

            // Checklists
            apply_regex_task_match (regex_task_done, text, true);
            apply_regex_task_match (regex_task_todo, text, false);

            // Standard Bullet Lists
            apply_regex_list_match (regex_list, text);

            // Multiline Code Blocks (triple backticks)
            apply_regex_code_block_match (regex_code_block, text);

            // Inline Formatting: Bold, Italic, Strikethrough, Code, Links
            apply_regex_inline_match (regex_bold, text, TAG_BOLD);
            apply_regex_inline_match (regex_italic, text, TAG_ITALIC);
            apply_regex_inline_match (regex_strike, text, TAG_STRIKETHROUGH);
            apply_regex_inline_match (regex_code, text, TAG_CODE);
            apply_regex_link_match (regex_link, text);

            is_highlighting = false;
        }

        private void apply_regex_line_match (GLib.Regex? regex, string text, string tag_name, int prefix_len) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int start_pos = 0;
                        int end_pos = 0;
                        if (info.fetch_pos (0, out start_pos, out end_pos)) {
                            Gtk.TextIter s, e, marker_e;
                            get_iter_at_offset (out s, start_pos);
                            get_iter_at_offset (out e, end_pos);
                            get_iter_at_offset (out marker_e, start_pos + prefix_len);

                            apply_tag_by_name (tag_name, s, e);
                            apply_tag_by_name (TAG_SYNTAX, s, marker_e);
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("Regex match error: %s", e.message);
            }
        }

        private void apply_regex_task_match (GLib.Regex? regex, string text, bool is_done) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int marker_start = 0;
                        int marker_end = 0;
                        int content_start = 0;
                        int content_end = 0;
                        if (info.fetch_pos (1, out marker_start, out marker_end) &&
                            info.fetch_pos (2, out content_start, out content_end)) {
                            Gtk.TextIter ms, me, cs, ce;
                            get_iter_at_offset (out ms, marker_start);
                            get_iter_at_offset (out me, marker_end);
                            get_iter_at_offset (out cs, content_start);
                            get_iter_at_offset (out ce, content_end);

                            apply_tag_by_name (TAG_LIST, ms, ce);
                            apply_tag_by_name (TAG_SYNTAX, ms, me);
                            if (is_done) {
                                apply_tag_by_name (TAG_TASK_DONE, cs, ce);
                            }
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("Task match error: %s", e.message);
            }
        }

        private void apply_regex_list_match (GLib.Regex? regex, string text) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int start_pos = 0;
                        int end_pos = 0;
                        if (info.fetch_pos (0, out start_pos, out end_pos)) {
                            Gtk.TextIter s, e;
                            get_iter_at_offset (out s, start_pos);
                            get_iter_at_offset (out e, end_pos);
                            apply_tag_by_name (TAG_LIST, s, e);
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("List match error: %s", e.message);
            }
        }

        private void apply_regex_inline_match (GLib.Regex? regex, string text, string content_tag) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int full_s = 0;
                        int full_e = 0;
                        int content_s = 0;
                        int content_e = 0;
                        if (info.fetch_pos (0, out full_s, out full_e) &&
                            info.fetch_pos (2, out content_s, out content_e)) {
                            Gtk.TextIter cs, ce;
                            get_iter_at_offset (out cs, content_s);
                            get_iter_at_offset (out ce, content_e);

                            Gtk.TextIter ds1, de1, ds2, de2;
                            get_iter_at_offset (out ds1, full_s);
                            get_iter_at_offset (out de1, content_s);
                            get_iter_at_offset (out ds2, content_e);
                            get_iter_at_offset (out de2, full_e);

                            apply_tag_by_name (TAG_SYNTAX, ds1, de1);
                            apply_tag_by_name (TAG_SYNTAX, ds2, de2);

                            if (content_tag == TAG_CODE) {
                                Gtk.TextIter fs, fe;
                                get_iter_at_offset (out fs, full_s);
                                get_iter_at_offset (out fe, full_e);
                                apply_tag_by_name (TAG_CODE, fs, fe);
                            } else {
                                apply_tag_by_name (content_tag, cs, ce);
                            }
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("Inline match error: %s", e.message);
            }
        }

        private void apply_regex_code_block_match (GLib.Regex? regex, string text) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int full_s = 0, full_e = 0;
                        int open_s = 0, open_e = 0;
                        int content_s = 0, content_e = 0;
                        int close_s = 0, close_e = 0;
                        if (info.fetch_pos (0, out full_s, out full_e) &&
                            info.fetch_pos (1, out open_s, out open_e) &&
                            info.fetch_pos (2, out content_s, out content_e) &&
                            info.fetch_pos (3, out close_s, out close_e)) {
                            Gtk.TextIter fs, fe, os, oe, cls, cle;
                            get_iter_at_offset (out fs, full_s);
                            get_iter_at_offset (out fe, full_e);
                            get_iter_at_offset (out os, open_s);
                            get_iter_at_offset (out oe, open_e);
                            get_iter_at_offset (out cls, close_s);
                            get_iter_at_offset (out cle, close_e);

                            apply_tag_by_name (TAG_CODE_BLOCK, fs, fe);
                            apply_tag_by_name (TAG_SYNTAX, os, oe);
                            apply_tag_by_name (TAG_SYNTAX, cls, cle);
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("Code block match error: %s", e.message);
            }
        }

        private void apply_regex_link_match (GLib.Regex? regex, string text) {
            if (regex == null) return;
            try {
                GLib.MatchInfo info;
                if (regex.match (text, 0, out info)) {
                    while (info.matches ()) {
                        int text_s = 0;
                        int text_e = 0;
                        if (info.fetch_pos (1, out text_s, out text_e)) {
                            Gtk.TextIter s, e;
                            get_iter_at_offset (out s, text_s);
                            get_iter_at_offset (out e, text_e);
                            apply_tag_by_name (TAG_LINK, s, e);
                        }
                        info.next ();
                    }
                }
            } catch (GLib.Error e) {
                debug ("Link match error: %s", e.message);
            }
        }

        /**
         * Helper to check if a line has a markdown list prefix.
         */
        public string? get_list_prefix (int line_number) {
            Gtk.TextIter start, end;
            get_iter_at_line_offset (out start, line_number, 0);
            end = start.copy ();
            end.forward_to_line_end ();

            var line_text = get_slice (start, end, false);

            if (line_text.has_prefix ("- [ ] ")) return "- [ ] ";
            if (line_text.has_prefix ("- [x] ")) return "- [ ] ";
            if (line_text.has_prefix ("* [ ] ")) return "* [ ] ";
            if (line_text.has_prefix ("* [x] ")) return "* [ ] ";
            if (line_text.has_prefix ("- ")) return "- ";
            if (line_text.has_prefix ("* ")) return "* ";
            if (line_text.has_prefix ("+ ")) return "+ ";

            return null;
        }
    }
}
