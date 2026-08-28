/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * Search popover for interactive, full-text note discovery and navigation.
     */
    public class SearchPopover : Gtk.Popover {
        private const int SPACING_STANDARD = 8;

        private weak NoteManager note_manager;
        private Gtk.SearchEntry search_entry;
        private Gtk.ListBox results_list;
        private Gtk.ScrolledWindow scrolled_window;
        private Gtk.Label status_label;
        private uint search_timeout_id = 0;
        private Gee.ArrayList<SearchResult> current_results;

        public SearchPopover (NoteManager manager) {
            this.note_manager = manager;
            this.current_results = new Gee.ArrayList<SearchResult> ();
            this.position = Gtk.PositionType.BOTTOM;
            this.autohide = true;
            this.has_arrow = true;
        }

        construct {
            var root_box = new Gtk.Box (Gtk.Orientation.VERTICAL, SPACING_STANDARD) {
                margin_top = SPACING_STANDARD,
                margin_bottom = SPACING_STANDARD,
                margin_start = SPACING_STANDARD,
                margin_end = SPACING_STANDARD,
                width_request = 320
            };

            search_entry = new Gtk.SearchEntry () {
                placeholder_text = _("Search notes… (Ctrl+F)"),
                hexpand = true
            };
            search_entry.search_changed.connect (on_search_changed);
            search_entry.activate.connect (on_entry_activate);

            var key_controller = new Gtk.EventControllerKey ();
            key_controller.key_pressed.connect (on_key_pressed);
            search_entry.add_controller (key_controller);

            results_list = new Gtk.ListBox () {
                selection_mode = Gtk.SelectionMode.SINGLE,
                show_separators = true
            };
            results_list.add_css_class ("frame");
            results_list.row_activated.connect (on_row_activated);

            scrolled_window = new Gtk.ScrolledWindow () {
                child = results_list,
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                max_content_height = 240,
                propagate_natural_height = true,
                min_content_height = 60,
                visible = false
            };

            status_label = new Gtk.Label (_("Type to search notes")) {
                margin_top = SPACING_DOUBLE,
                margin_bottom = SPACING_DOUBLE
            };
            status_label.add_css_class ("dim-label");

            root_box.append (search_entry);
            root_box.append (status_label);
            root_box.append (scrolled_window);

            child = root_box;

            this.closed.connect (() => {
                if (search_timeout_id != 0) {
                    Source.remove (search_timeout_id);
                    search_timeout_id = 0;
                }
            });
        }

        public void focus_and_select () {
            search_entry.grab_focus ();
            search_entry.select_region (0, -1);
        }

        private void on_search_changed () {
            if (search_timeout_id != 0) {
                Source.remove (search_timeout_id);
                search_timeout_id = 0;
            }

            search_timeout_id = Timeout.add (120, () => {
                search_timeout_id = 0;
                execute_search (search_entry.text);
                return Source.REMOVE;
            });
        }

        private void execute_search (string query) {
            var stripped = query.strip ();
            clear_results ();

            if (stripped.length == 0) {
                status_label.set_text (_("Type to search notes"));
                status_label.visible = true;
                scrolled_window.visible = false;
                return;
            }

            current_results = note_manager.search_service.search (stripped);

            if (current_results.size == 0) {
                status_label.set_text (_("No matching notes found"));
                status_label.visible = true;
                scrolled_window.visible = false;
                return;
            }

            status_label.visible = false;
            scrolled_window.visible = true;

            foreach (var res in current_results) {
                results_list.append (create_result_row (res));
            }

            var first_row = results_list.get_row_at_index (0);
            if (first_row != null) {
                results_list.select_row (first_row);
            }
        }

        private Gtk.Widget create_result_row (SearchResult res) {
            var row_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) {
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 8,
                margin_end = 8
            };

            // Top Header: Theme Pill + Title + Badge
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                hexpand = true
            };

            var color_pill = new Jots.ColorPill (res.theme, null) {
                width_request = 10,
                height_request = 10,
                valign = Gtk.Align.CENTER,
                can_target = false,
                focusable = false
            };
            color_pill.set_action_name (null);

            var title_label = new Gtk.Label (res.title) {
                hexpand = true,
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "heading" }
            };
            title_label.add_css_class ("title-4");

            header_box.append (color_pill);
            header_box.append (title_label);

            if (res.is_active) {
                var active_badge = new Gtk.Label (_("Open")) {
                    valign = Gtk.Align.CENTER,
                    css_classes = { "badge" }
                };
                active_badge.add_css_class ("dim-label");
                header_box.append (active_badge);
            }

            // Bottom Snippet: Formatted markup
            var snippet_label = new Gtk.Label (null) {
                use_markup = true,
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END,
                max_width_chars = 40,
                lines = 1
            };
            snippet_label.set_markup (res.snippet);
            snippet_label.add_css_class ("dim-label");

            row_box.append (header_box);
            row_box.append (snippet_label);

            return row_box;
        }

        private void on_row_activated (Gtk.ListBoxRow row) {
            int index = row.get_index ();
            if (index >= 0 && index < current_results.size) {
                var result = current_results.get (index);
                popdown ();
                note_manager.open_note_by_id (result.id);
            }
        }

        private void on_entry_activate () {
            if (search_timeout_id != 0) {
                Source.remove (search_timeout_id);
                search_timeout_id = 0;
                execute_search (search_entry.text);
            }

            var selected_row = results_list.get_selected_row ();
            if (selected_row != null) {
                on_row_activated (selected_row);
            } else if (current_results.size > 0) {
                var first = results_list.get_row_at_index (0);
                if (first != null) {
                    on_row_activated (first);
                }
            }
        }

        private bool on_key_pressed (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
            if (keyval == Gdk.Key.Down) {
                var selected = results_list.get_selected_row ();
                int next_idx = (selected != null) ? selected.get_index () + 1 : 0;
                if (next_idx < current_results.size) {
                    var next_row = results_list.get_row_at_index (next_idx);
                    if (next_row != null) {
                        results_list.select_row (next_row);
                        return true;
                    }
                }
            } else if (keyval == Gdk.Key.Up) {
                var selected = results_list.get_selected_row ();
                int prev_idx = (selected != null) ? selected.get_index () - 1 : -1;
                if (prev_idx >= 0) {
                    var prev_row = results_list.get_row_at_index (prev_idx);
                    if (prev_row != null) {
                        results_list.select_row (prev_row);
                        return true;
                    }
                }
            } else if (keyval == Gdk.Key.Escape) {
                popdown ();
                return true;
            }
            return false;
        }

        private void clear_results () {
            current_results.clear ();
            Gtk.Widget? child = results_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                results_list.remove (child);
                child = next;
            }
        }

        ~SearchPopover () {
            if (search_timeout_id != 0) {
                Source.remove (search_timeout_id);
                search_timeout_id = 0;
            }
        }
    }
}
