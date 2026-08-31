/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * A text view for sticky notes with native Markdown rendering, URL navigation, and smart formatting.
     */
    public class TextView : Gtk.TextView {

        public Jots.MarkdownBuffer markdown_buffer;

        private Gtk.EventControllerKey keyboard;

        public signal void link_activated (string uri);

        public string text {
            owned get { return buffer.text; }
            set {
                buffer.text = value;
                markdown_buffer.highlight_markdown ();
            }
        }

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "textview.";
        public const string ACTION_TOGGLE_LIST = "action_toggle_list";
        public const string ACTION_PASTE_RAW = "action_paste_raw";
        public const string ACTION_PASTE_SMART = "action_paste_smart";

        public signal void paste_normalized (string message);

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
            { ACTION_TOGGLE_LIST, toggle_list },
            { ACTION_PASTE_RAW, paste_raw },
            { ACTION_PASTE_SMART, paste_smart }
        };

        public TextView () {
            Object (
                wrap_mode: Gtk.WrapMode.WORD_CHAR,
                bottom_margin: SPACING_DOUBLE,
                left_margin: SPACING_DOUBLE,
                right_margin: SPACING_DOUBLE,
                top_margin: SPACING_STANDARD,
                hexpand: true,
                vexpand: true
            );
        }

        construct {
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("textview", actions);

            var app = GLib.Application.get_default () as Gtk.Application;
            if (app != null) {
                app.set_accels_for_action (ACTION_PREFIX + ACTION_TOGGLE_LIST, {"<Shift>F12"});
                app.set_accels_for_action (ACTION_PREFIX + ACTION_PASTE_RAW, {"<Control><Shift>v", "<Control><Shift>V"});
            }

            keyboard = new Gtk.EventControllerKey ();
            keyboard.key_pressed.connect (on_key_pressed);
            add_controller (keyboard);

            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (on_click_released);
            add_controller (click_gesture);

            var motion = new Gtk.EventControllerMotion ();
            motion.motion.connect (on_mouse_motion);
            motion.leave.connect (on_mouse_leave);
            add_controller (motion);

            // Context menu items
            var menuitem_paste_raw = new GLib.MenuItem (
                _("Paste Without Formatting"),
                ACTION_PREFIX + ACTION_PASTE_RAW
            );

            var menuitem_pref = new GLib.MenuItem (
                _("Show Preferences"),
                Application.ACTION_PREFIX + Application.ACTION_SHOW_PREFERENCES
            );

            var menuitem_quit = new GLib.MenuItem (
                _("Quit Jots"),
                Application.ACTION_PREFIX + Application.ACTION_QUIT
            );

            var extra = new GLib.Menu ();
            var section_paste = new GLib.Menu ();
            var section_app = new GLib.Menu ();

            section_paste.append_item (menuitem_paste_raw);
            extra.append_section (null, section_paste);

            section_app.append_item (menuitem_pref);
            section_app.append_item (menuitem_quit);
            extra.append_section (null, section_app);
            extra_menu = extra;

            markdown_buffer = new Jots.MarkdownBuffer ();
            buffer = (Gtk.TextBuffer) markdown_buffer;
        }

        private void on_click_released (Gtk.GestureClick gesture, int n_press, double x, double y) {
            int bx, by;
            window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)x, (int)y, out bx, out by);

            Gtk.TextIter iter;
            get_iter_at_location (out iter, bx, by);

            foreach (var tag in iter.get_tags ()) {
                if (tag.name != null && tag.name.has_prefix ("url:")) {
                    var uri = tag.name.substring ("url:".length);
                    link_activated (uri);
                    var uri_launcher = new Gtk.UriLauncher (uri);
                    uri_launcher.launch.begin (get_root () as Gtk.Window, null, (obj, res) => {
                        try {
                            uri_launcher.launch.end (res);
                        } catch (GLib.Error e) {
                            warning ("Failed to open URI %s: %s", uri, e.message);
                        }
                    });
                    break;
                }
            }
        }

        private void on_mouse_motion (Gtk.EventControllerMotion controller, double x, double y) {
            int bx, by;
            window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)x, (int)y, out bx, out by);

            Gtk.TextIter iter;
            get_iter_at_location (out iter, bx, by);

            bool on_link = false;
            foreach (var tag in iter.get_tags ()) {
                if (tag.name != null && tag.name.has_prefix ("url:")) {
                    on_link = true;
                    break;
                }
            }

            set_cursor_from_name (on_link ? "pointer" : "text");
        }

        private void on_mouse_leave () {
            set_cursor_from_name (null);
        }

        public void toggle_list () {
            Gtk.TextIter start, end;
            buffer.get_selection_bounds (out start, out end);

            var first_line = start.get_line ();
            var last_line = end.get_line ();

            buffer.begin_user_action ();
            for (int line = first_line; line <= last_line; line++) {
                Gtk.TextIter line_start, line_end;
                buffer.get_iter_at_line_offset (out line_start, line, 0);
                line_end = line_start.copy ();
                line_end.forward_to_line_end ();
                var line_str = buffer.get_slice (line_start, line_end, false);

                if (line_str.has_prefix ("- ")) {
                    // Remove prefix
                    Gtk.TextIter prefix_end;
                    buffer.get_iter_at_line_offset (out prefix_end, line, 2);
                    buffer.delete (ref line_start, ref prefix_end);
                } else {
                    // Add prefix
                    buffer.insert (ref line_start, "- ", -1);
                }
            }
            buffer.end_user_action ();

            markdown_buffer.highlight_markdown ();
            grab_focus ();
        }

        private bool on_key_pressed (uint keyval, uint keycode, Gdk.ModifierType state) {
            if (keyval == Gdk.Key.Return) {
                Gtk.TextIter cursor;
                var insert_mark = buffer.get_insert ();
                buffer.get_iter_at_mark (out cursor, insert_mark);
                var line_number = cursor.get_line ();

                Gtk.TextIter line_start, line_end;
                buffer.get_iter_at_line_offset (out line_start, line_number, 0);
                line_end = line_start.copy ();
                line_end.forward_to_line_end ();
                var line_text = buffer.get_slice (line_start, line_end, false);

                string? prefix = markdown_buffer.get_list_prefix (line_number);
                if (prefix != null) {
                    // If the line consists only of the prefix, clear it and break list
                    if (line_text.strip () == prefix.strip ()) {
                        buffer.begin_user_action ();
                        buffer.delete (ref line_start, ref line_end);
                        buffer.end_user_action ();
                        return true;
                    }

                    // Otherwise, insert newline with prefix
                    buffer.begin_user_action ();
                    buffer.insert_at_cursor ("\n" + prefix, -1);
                    buffer.end_user_action ();
                    return true;
                }
            } else if (keyval == Gdk.Key.BackSpace) {
                Gtk.TextIter cursor;
                var insert_mark = buffer.get_insert ();
                buffer.get_iter_at_mark (out cursor, insert_mark);
                var line_number = cursor.get_line ();

                Gtk.TextIter line_start, line_end;
                buffer.get_iter_at_line_offset (out line_start, line_number, 0);
                line_end = line_start.copy ();
                line_end.forward_to_line_end ();
                var line_text = buffer.get_slice (line_start, line_end, false);

                string? prefix = markdown_buffer.get_list_prefix (line_number);
                if (prefix != null && line_text == prefix) {
                    buffer.begin_user_action ();
                    buffer.delete (ref line_start, ref line_end);
                    buffer.end_user_action ();
                    return true;
                }
            } else if ((keyval == Gdk.Key.v || keyval == Gdk.Key.V) && (state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                if ((state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                    paste_raw ();
                    return true;
                } else {
                    paste_smart ();
                    return true;
                }
            }

            return false;
        }

        /**
         * Smart paste: checks context (code vs text), converts HTML/rich-text or normalizes loose Markdown,
         * and notifies user if altered.
         */
        public void paste_smart () {
            Gtk.TextIter cursor;
            var insert_mark = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor, insert_mark);

            if (markdown_buffer.is_code_context (cursor)) {
                paste_raw ();
                return;
            }

            var clipboard = get_clipboard ();
            var formats = clipboard.get_formats ();

            if (formats.contain_mime_type ("text/html")) {
                clipboard.read_async.begin ({"text/html"}, Priority.DEFAULT, null, (obj, res) => {
                    try {
                        string out_mime_type;
                        var stream = clipboard.read_async.end (res, out out_mime_type);
                        if (stream == null) {
                            read_and_normalize_plain_text (clipboard);
                            return;
                        }

                        var mem_stream = new GLib.MemoryOutputStream.resizable ();
                        mem_stream.splice_async.begin (stream, GLib.OutputStreamSpliceFlags.CLOSE_SOURCE | GLib.OutputStreamSpliceFlags.CLOSE_TARGET, Priority.DEFAULT, null, (s_obj, s_res) => {
                            try {
                                mem_stream.splice_async.end (s_res);
                                uint8[] null_byte = { 0 };
                                mem_stream.write (null_byte);
                                var bytes = mem_stream.steal_as_bytes ();
                                unowned uint8[] data = bytes.get_data ();

                                if (data.length > 1) {
                                    var html_str = (string) data;
                                    if (!html_str.validate ()) {
                                        html_str = html_str.make_valid ();
                                    }
                                    var converted = Jots.Utils.HtmlToMarkdown.convert (html_str);
                                    var normalized = Jots.Utils.MarkdownNormalizer.normalize (converted);

                                    if (normalized.length > 0) {
                                        paste_normalized (_("Formatted as Markdown (Ctrl+Shift+V for raw)"));
                                        insert_text_atomic (normalized);
                                        return;
                                    }
                                }
                            } catch (GLib.Error e) {
                                debug ("Failed to splice HTML stream: %s", e.message);
                            }

                            read_and_normalize_plain_text (clipboard);
                        });
                        return;
                    } catch (GLib.Error e) {
                        debug ("Failed to read HTML clipboard stream: %s", e.message);
                    }

                    read_and_normalize_plain_text (clipboard);
                });
            } else {
                read_and_normalize_plain_text (clipboard);
            }
        }

        private void read_and_normalize_plain_text (Gdk.Clipboard clipboard) {
            clipboard.read_text_async.begin (null, (obj, res) => {
                try {
                    var raw_text = clipboard.read_text_async.end (res);
                    if (raw_text != null && raw_text.length > 0) {
                        var normalized = Jots.Utils.MarkdownNormalizer.normalize (raw_text);
                        if (normalized != raw_text) {
                            paste_normalized (_("Formatted as Markdown (Ctrl+Shift+V for raw)"));
                        }
                        insert_text_atomic (normalized);
                    }
                } catch (GLib.Error e) {
                    debug ("Failed to read clipboard text: %s", e.message);
                }
            });
        }

        /**
         * Raw paste: bypasses all normalizations and inserts literal clipboard text.
         */
        public void paste_raw () {
            var clipboard = get_clipboard ();
            clipboard.read_text_async.begin (null, (obj, res) => {
                try {
                    var raw_text = clipboard.read_text_async.end (res);
                    if (raw_text != null && raw_text.length > 0) {
                        insert_text_atomic (raw_text);
                    }
                } catch (GLib.Error e) {
                    debug ("Failed to read raw clipboard text: %s", e.message);
                }
            });
        }

        /**
         * Inserts text atomically within a single undo/redo transaction.
         */
        public void insert_text_atomic (string text) {
            buffer.begin_user_action ();
            if (buffer.get_has_selection ()) {
                buffer.delete_selection (true, true);
            }
            buffer.insert_at_cursor (text, -1);
            buffer.end_user_action ();
            markdown_buffer.highlight_markdown ();
        }

        public void queue_refresh_indentation () {
            refresh_indentation ();
        }

        public void refresh_indentation () {
            markdown_buffer.highlight_markdown ();
        }

        ~TextView () {
            debug ("Destroyed");
        }
    }
}
