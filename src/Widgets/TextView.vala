/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

namespace Jots {

    /**
     * A text view for sticky notes with native Markdown rendering, URL navigation, and smart formatting.
     */
    public class TextView : Gtk.TextView {

        public Jots.MarkdownBuffer markdown_buffer;

        private Gtk.EventControllerKey keyboard;
        private Gdk.FrameClock? frame_clock;

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

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
            { ACTION_TOGGLE_LIST, toggle_list }
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

            unowned var app = ((Gtk.Application) GLib.Application.get_default ());
            app.set_accels_for_action (ACTION_PREFIX + ACTION_TOGGLE_LIST, {"<Shift>F12"});

            keyboard = new Gtk.EventControllerKey ();
            keyboard.key_pressed.connect (on_key_pressed);
            add_controller (keyboard);

            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (on_click_released);
            add_controller (click_gesture);

            var motion = new Gtk.EventControllerMotion ();
            motion.motion.connect (on_mouse_motion);
            motion.leave.connect (() => { set_cursor_from_name (null); });
            add_controller (motion);

            // Context menu items
            var menuitem_pref = new GLib.MenuItem (
                _("Show Preferences"),
                Application.ACTION_PREFIX + Application.ACTION_SHOW_PREFERENCES
            );

            var menuitem_quit = new GLib.MenuItem (
                _("Quit Jots"),
                Application.ACTION_PREFIX + Application.ACTION_QUIT
            );

            var extra = new GLib.Menu ();
            var section = new GLib.Menu ();

            section.append_item (menuitem_pref);
            section.append_item (menuitem_quit);
            extra.append_section (null, section);
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
                    try {
                        Gtk.show_uri (get_root () as Gtk.Window, uri, Gdk.CURRENT_TIME);
                    } catch (Error e) {
                        warning ("Failed to open URI %s: %s", uri, e.message);
                    }
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
            }

            return false;
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
