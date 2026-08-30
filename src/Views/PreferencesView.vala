/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    public class ToastBanner : Jots.Bin {
        private Gtk.Revealer revealer;
        private Gtk.Label label;
        private uint timeout_id = 0;

        public string title {
            get { return label.label; }
            set { label.label = value; }
        }

        public ToastBanner () {
            valign = Gtk.Align.START;
            halign = Gtk.Align.CENTER;
            margin_top = SPACING_DOUBLE;

            revealer = new Gtk.Revealer () {
                reveal_child = false,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
            };

            label = new Gtk.Label ("") {
                css_classes = { "app-notification", "frame" },
                margin_start = 12,
                margin_end = 12,
                margin_top = 6,
                margin_bottom = 6
            };
            revealer.child = label;
            child = revealer;
        }

        public void send_notification (uint duration_ms = 3000) {
            revealer.reveal_child = true;
            if (timeout_id != 0) {
                Source.remove (timeout_id);
            }
            timeout_id = Timeout.add_once (duration_ms, () => {
                revealer.reveal_child = false;
                timeout_id = 0;
            });
        }

        ~ToastBanner () {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
        }
    }

    public class PreferencesView : Jots.Bin {

        private ToastBanner toast;
        public Gtk.Button close_button;
        public Gtk.StackSwitcher page_switcher { get; private set; }
        private Gtk.Stack page_stack;

#if LIBPORTAL
        Gtk.Switch autostart_toggle;
        Jots.Autostart autostart;
#endif

        construct {
            var prefview = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                margin_start = SPACING_DOUBLE,
                margin_end = SPACING_DOUBLE,
                margin_top = SPACING_DOUBLE,
                margin_bottom = SPACING_DOUBLE,
                hexpand = true,
                vexpand = true
            };

            var overlay = new Gtk.Overlay () {
                child = prefview
            };

            toast = new ToastBanner ();
            overlay.add_overlay (toast);
            child = overlay;

            page_stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
                hexpand = true,
                vexpand = true
            };

            page_switcher = new Gtk.StackSwitcher () {
                stack = page_stack,
                halign = Gtk.Align.CENTER
            };

            page_stack.add_titled (build_general_page (), "general", _("General"));
            page_stack.add_titled (build_appearance_page (), "appearance", _("Appearance"));
            page_stack.add_titled (build_data_page (), "data", _("Data & Recovery"));
            page_stack.add_titled (build_backup_page (), "backup", _("Backup & Sync"));

            /*************************************************/
            // Bar at the bottom
            var actionbar = new Gtk.CenterBox () {
                valign = Gtk.Align.END,
                margin_top = SPACING_TRIPLE + SPACING_DOUBLE,
                hexpand = true,
                vexpand = false
            };

            actionbar.start_widget = new Gtk.LinkButton.with_label (
                COMMUNITY_LINK,
                _("Get help")
            );

            var right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, Jots.SPACING_DOUBLE);
            actionbar.end_widget = right_box;

            var close = new Gtk.Button () {
                action_name = "window.close",
                width_request = 96,
                label = _("Close"),
                tooltip_markup = Jots.Util.markup_accel_tooltip (
                    _("Close preferences"),
                    "Alt+F4"
                )
            };
            close_button = close;
            right_box.append (close);

            prefview.append (page_stack);
            prefview.append (actionbar);
        }

        private Gtk.Widget wrap_page (Gtk.Box content) {
            var scrolled = new Gtk.ScrolledWindow () {
                hexpand = true,
                vexpand = true,
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                min_content_height = 240,
                child = content
            };
            return scrolled;
        }

        private Gtk.Box make_page_box () {
            return new Gtk.Box (Gtk.Orientation.VERTICAL, SPACING_DOUBLE) {
                margin_start = SPACING_DOUBLE,
                margin_end = SPACING_DOUBLE,
                margin_top = SPACING_DOUBLE,
                margin_bottom = SPACING_DOUBLE,
                hexpand = true,
                vexpand = true,
                valign = Gtk.Align.START
            };
        }

        private Gtk.Widget build_general_page () {
            var page = make_page_box ();

            var list_dropdown = new Gtk.DropDown.from_strings (ListPrefix.ALL) {
                halign = Gtk.Align.END,
                hexpand = false,
                valign = Gtk.Align.CENTER
            };
            list_dropdown.selected = Application.settings.get_enum (KEY_LIST);
            list_dropdown.notify["selected"].connect (() => {
                Application.settings.set_enum (KEY_LIST, (int) list_dropdown.selected);
            });

            var lists_box = new SettingsBox (
                _("List item prefix"),
                null,
                list_dropdown
            );
            page.append (lists_box);

#if LIBPORTAL
            autostart_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_AUTOSTART,
                autostart_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            autostart = new Jots.Autostart ();
            autostart_toggle.notify["state"].connect (handle_toggle_autostart);

            var autostart_box = new Jots.SettingsBox (
                _("Show notes on log in"),
                _("May be out of sync with system settings in some cases"),
                autostart_toggle
            );
            page.append (autostart_box);
#endif

            return wrap_page (page);
        }

        private Gtk.Widget build_appearance_page () {
            var page = make_page_box ();

            var scribbly_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_SCRIBBLY,
                scribbly_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var scribbly_box = new Jots.SettingsBox (
                _("Scribble unfocused notes (Ctrl+H)"),
                null,
                scribbly_toggle
            );
            page.append (scribbly_box);

            var hidebar_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_HIDEBAR,
                hidebar_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var hidebar_box = new Jots.SettingsBox (
                _("Hide bottom bar (Ctrl+T)"),
                null,
                hidebar_toggle
            );
            page.append (hidebar_box);

            var custom_fonts_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_CUSTOM_FONTS,
                custom_fonts_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var custom_fonts_box = new Jots.SettingsBox (
                _("Use custom fonts"),
                _("Override system default fonts for sticky notes"),
                custom_fonts_toggle
            );
            page.append (custom_fonts_box);

            var default_dialog = new Gtk.FontDialog ();
            var default_font_btn = new Gtk.FontDialogButton (default_dialog) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            var saved_default_font = Application.settings.get_string (KEY_DEFAULT_FONT);
            var initial_default_desc = (saved_default_font.strip () != "")
                ? saved_default_font
                : FontController.get_system_default_font ();
            default_font_btn.font_desc = Pango.FontDescription.from_string (initial_default_desc);

            default_font_btn.notify["font-desc"].connect (() => {
                if (default_font_btn.font_desc != null) {
                    Application.settings.set_string (KEY_DEFAULT_FONT, default_font_btn.font_desc.to_string ());
                }
            });

            var default_font_box = new Jots.SettingsBox (
                _("Default note font"),
                _("Font used for standard notes"),
                default_font_btn
            );
            page.append (default_font_box);

            var mono_dialog = new Gtk.FontDialog ();
            var mono_filter = new Gtk.CustomFilter ((item) => {
                var family = item as Pango.FontFamily;
                if (family != null) {
                    return family.is_monospace ();
                }
                var face = item as Pango.FontFace;
                if (face != null) {
                    var fam = face.get_family ();
                    return fam != null && fam.is_monospace ();
                }
                return false;
            });
            mono_dialog.filter = mono_filter;

            var mono_font_btn = new Gtk.FontDialogButton (mono_dialog) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            var saved_mono_font = Application.settings.get_string (KEY_MONOSPACE_FONT);
            var initial_mono_desc = (saved_mono_font.strip () != "")
                ? saved_mono_font
                : FontController.get_system_monospace_font ();
            mono_font_btn.font_desc = Pango.FontDescription.from_string (initial_mono_desc);

            mono_font_btn.notify["font-desc"].connect (() => {
                if (mono_font_btn.font_desc != null) {
                    Application.settings.set_string (KEY_MONOSPACE_FONT, mono_font_btn.font_desc.to_string ());
                }
            });

            var mono_font_box = new Jots.SettingsBox (
                _("Monospace note font"),
                _("Font used for monospace notes (Ctrl+M)"),
                mono_font_btn
            );
            page.append (mono_font_box);

            custom_fonts_toggle.bind_property ("active", default_font_btn, "sensitive", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
            custom_fonts_toggle.bind_property ("active", mono_font_btn, "sensitive", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

            return wrap_page (page);
        }

        private Gtk.Widget build_data_page () {
            var page = make_page_box ();

            var restore_button = new Gtk.Button () {
                label = _("Restore note"),
                tooltip_markup = Jots.Util.markup_accel_tooltip (
                    _("Restore the last deleted sticky note"),
                    "Ctrl+R"
                ),
                action_name = Application.ACTION_PREFIX + Application.ACTION_RESTORE_LAST,
                width_request = 96,
            };

            var restore_box = new Jots.SettingsBox (
                _("Restore note"),
                _("Restore the last deleted sticky note"),
                restore_button
            );
            page.append (restore_box);

            var import_jorts_button = new Gtk.Button () {
                label = _("Import Notes"),
                tooltip_text = _("Scan and import notes from an existing Jorts installation"),
                valign = Gtk.Align.CENTER,
                width_request = 96
            };

            import_jorts_button.clicked.connect (() => {
                var count = Application.note_manager.import_from_jorts ();
                if (count > 0) {
                    toast.title = _("Successfully imported %d notes from Jorts").printf (count);
                    toast.send_notification ();
                } else {
                    toast.title = _("No Jorts notes found on system");
                    toast.send_notification ();
                }
            });

            var import_jorts_box = new Jots.SettingsBox (
                _("Import from Jorts"),
                _("Copy notes from an existing Jorts installation without modifying originals"),
                import_jorts_button
            );
            page.append (import_jorts_box);

            return wrap_page (page);
        }

        private Gtk.Widget build_backup_page () {
            var page = make_page_box ();

            var status_value = new Gtk.Label (Application.settings.get_string (KEY_BACKUP_SYNC_STATUS)) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER,
                xalign = 1.0f
            };
            status_value.add_css_class ("dim-label");
            page.append (new Jots.SettingsBox (_("Status"), _("Current backup and sync state"), status_value));

            var last_sync_value = new Gtk.Label (Application.settings.get_string (KEY_BACKUP_SYNC_LAST_SYNC)) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER,
                xalign = 1.0f
            };
            last_sync_value.add_css_class ("dim-label");
            page.append (new Jots.SettingsBox (_("Last successful sync"), null, last_sync_value));

            var enable_toggle = new Gtk.Switch () {
                sensitive = false
            };
            Application.settings.bind (KEY_BACKUP_SYNC_ENABLED,
                enable_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);
            page.append (new Jots.SettingsBox (_("Enable backup and sync"), _("Coming soon in the next phase"), enable_toggle));

            var remote_entry = new Gtk.Entry () {
                placeholder_text = _("https://example.com/notes.git"),
                valign = Gtk.Align.CENTER,
                sensitive = false,
                width_chars = 24
            };
            Application.settings.bind (KEY_BACKUP_SYNC_REMOTE_URL,
                remote_entry, "text",
                GLib.SettingsBindFlags.DEFAULT);
            page.append (new Jots.SettingsBox (_("Remote repository URL"), _("Stored now; not wired to sync engine yet"), remote_entry));

            string[] cadence_items = {
                _("Disabled"),
                _("Every 5 min"),
                _("Every 15 min"),
                _("Every 30 min"),
                _("Hourly")
            };
            var cadence_dropdown = new Gtk.DropDown.from_strings (cadence_items) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER,
                sensitive = false
            };
            cadence_dropdown.selected = Application.settings.get_enum (KEY_BACKUP_SYNC_CADENCE);
            cadence_dropdown.notify["selected"].connect (() => {
                Application.settings.set_enum (KEY_BACKUP_SYNC_CADENCE, (int) cadence_dropdown.selected);
            });
            page.append (new Jots.SettingsBox (_("Sync cadence"), _("Preference scaffold only for now"), cadence_dropdown));

            var sync_now_button = new Gtk.Button () {
                label = _("Sync now"),
                sensitive = false,
                width_request = 96
            };
            page.append (new Jots.SettingsBox (_("Immediate sync"), _("Will be enabled when backup backend is implemented"), sync_now_button));

            var test_connection_button = new Gtk.Button () {
                label = _("Test connection"),
                sensitive = false,
                width_request = 96
            };
            page.append (new Jots.SettingsBox (_("Remote check"), _("Will verify remote reachability in a future update"), test_connection_button));

            return wrap_page (page);
        }

#if LIBPORTAL
        private void handle_toggle_autostart () {
            if (autostart_toggle.active) {
                autostart.request_set.begin ();
                return;
            }

            autostart.request_remove.begin ();
        }
#endif
    }
}
