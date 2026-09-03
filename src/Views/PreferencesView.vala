/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    public class PreferencesView : Jots.Bin {

        private ToastBanner toast;
        public Gtk.Button close_button;
        public Gtk.StackSwitcher page_switcher { get; private set; }
        private Gtk.Stack page_stack;
        private Gtk.DropDown? cadence_dropdown = null;
        private Gtk.FontDialogButton? default_font_button = null;
        private Gtk.FontDialogButton? mono_font_button = null;
        private Gtk.Button? import_jorts_button = null;
        private Gtk.Button? sync_now_button = null;
        private Gtk.Button? test_connection_button = null;
        private ulong cadence_dropdown_handler_id = 0;
        private ulong default_font_button_handler_id = 0;
        private ulong mono_font_button_handler_id = 0;
        private ulong import_jorts_button_handler_id = 0;
        private ulong sync_now_button_handler_id = 0;
        private ulong test_connection_button_handler_id = 0;
        private ulong backup_enabled_handler_id = 0;
        private ulong backup_remote_url_handler_id = 0;

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
                _("Auto-hide bottom bar (Ctrl+T)"),
                _("Smoothly hide toolbar when notes lose focus; reveal on hover or click"),
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
            default_font_button = default_font_btn;
            var saved_default_font = Application.settings.get_string (KEY_DEFAULT_FONT);
            var initial_default_desc = (saved_default_font != null && saved_default_font.strip () != "")
                ? saved_default_font
                : FontController.get_system_default_font ();
            default_font_btn.font_desc = Pango.FontDescription.from_string (initial_default_desc);

            default_font_button_handler_id = default_font_btn.notify["font-desc"].connect (() => {
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
            mono_font_button = mono_font_btn;
            var saved_mono_font = Application.settings.get_string (KEY_MONOSPACE_FONT);
            var initial_mono_desc = (saved_mono_font != null && saved_mono_font.strip () != "")
                ? saved_mono_font
                : FontController.get_system_monospace_font ();
            mono_font_btn.font_desc = Pango.FontDescription.from_string (initial_mono_desc);

            mono_font_button_handler_id = mono_font_btn.notify["font-desc"].connect (() => {
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

            var import_jorts_btn = new Gtk.Button () {
                label = _("Import Notes"),
                tooltip_text = _("Scan and import notes from an existing Jorts installation"),
                valign = Gtk.Align.CENTER,
                width_request = 96
            };
            import_jorts_button = import_jorts_btn;

            import_jorts_button_handler_id = import_jorts_btn.clicked.connect (() => {
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
                import_jorts_btn
            );
            page.append (import_jorts_box);

            return wrap_page (page);
        }

        private Gtk.Widget build_backup_page () {
            var page = make_page_box ();

            var status_str = Application.settings.get_string (KEY_BACKUP_SYNC_STATUS);
            var status_value = new Gtk.Label (status_str ?? "") {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER,
                xalign = 1.0f
            };
            status_value.add_css_class ("dim-label");
            Application.settings.bind (KEY_BACKUP_SYNC_STATUS,
                status_value, "label",
                GLib.SettingsBindFlags.DEFAULT);

            var last_sync_str = Application.settings.get_string (KEY_BACKUP_SYNC_LAST_SYNC);
            var last_sync_value = new Gtk.Label (last_sync_str ?? "") {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER,
                xalign = 1.0f
            };
            last_sync_value.add_css_class ("dim-label");
            Application.settings.bind (KEY_BACKUP_SYNC_LAST_SYNC,
                last_sync_value, "label",
                GLib.SettingsBindFlags.DEFAULT);

            var enable_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_BACKUP_SYNC_ENABLED,
                enable_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);
            page.append (new Jots.SettingsBox (_("Enable backup and sync"), _("Prepares and manages a local Git backup repository"), enable_toggle));

            var remote_entry = new Gtk.Entry () {
                placeholder_text = _("https://example.com/notes.git"),
                valign = Gtk.Align.CENTER,
                width_chars = 24
            };
            Application.settings.bind (KEY_BACKUP_SYNC_REMOTE_URL,
                remote_entry, "text",
                GLib.SettingsBindFlags.DEFAULT);
            page.append (new Jots.SettingsBox (_("Remote repository URL"), _("Used for scheduled and manual backup synchronization"), remote_entry));

            string[] cadence_items = {
                _("Disabled"),
                _("Every 5 min"),
                _("Every 15 min"),
                _("Every 30 min"),
                _("Hourly"),
                null
            };
            var cadence_dropdown_widget = new Gtk.DropDown.from_strings (cadence_items) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            cadence_dropdown = cadence_dropdown_widget;
            cadence_dropdown.selected = Application.settings.get_enum (KEY_BACKUP_SYNC_CADENCE);
            cadence_dropdown_handler_id = cadence_dropdown_widget.notify["selected"].connect (() => {
                Application.settings.set_enum (KEY_BACKUP_SYNC_CADENCE, (int) cadence_dropdown_widget.selected);
            });
            page.append (new Jots.SettingsBox (_("Sync cadence"), _("Controls automatic remote backup checks"), cadence_dropdown_widget));

            var sync_now_btn = new Gtk.Button () {
                label = _("Sync now"),
                sensitive = false,
                width_request = 96
            };
            sync_now_button = sync_now_btn;
            page.append (new Jots.SettingsBox (_("Immediate sync"), _("Run backup synchronization with the configured remote now"), sync_now_btn));

            var test_connection_btn = new Gtk.Button () {
                label = _("Test connection"),
                sensitive = false,
                width_request = 96
            };
            test_connection_button = test_connection_btn;
            page.append (new Jots.SettingsBox (_("Remote check"), _("Verify reachability for the configured remote repository"), test_connection_btn));

            sync_now_button_handler_id = sync_now_btn.clicked.connect (() => {
                if (Application.git_sync_service == null) {
                    return;
                }

                Application.git_sync_service.request_remote_sync_now ();
                toast.title = _("Remote sync requested");
                toast.send_notification ();
            });

            test_connection_button_handler_id = test_connection_btn.clicked.connect (() => {
                if (Application.git_sync_service == null) {
                    return;
                }

                Application.git_sync_service.test_remote_connection_async.begin ((obj, res) => {
                    bool reachable = Application.git_sync_service.test_remote_connection_async.end (res);
                    toast.title = reachable
                        ? _("Remote repository is reachable")
                        : _("Remote repository check failed");

                    toast.send_notification ();
                });
            });

            backup_enabled_handler_id = Application.settings.changed[KEY_BACKUP_SYNC_ENABLED].connect (() => {
                update_backup_action_sensitivity (sync_now_btn, test_connection_btn);
            });
            backup_remote_url_handler_id = Application.settings.changed[KEY_BACKUP_SYNC_REMOTE_URL].connect (() => {
                update_backup_action_sensitivity (sync_now_btn, test_connection_btn);
            });
            update_backup_action_sensitivity (sync_now_btn, test_connection_btn);

            page.append (new Jots.SettingsBox (_("Status"), _("Current backup and sync state"), status_value));
            page.append (new Jots.SettingsBox (_("Last successful sync"), null, last_sync_value));

            return wrap_page (page);
        }

        ~PreferencesView () {
            if (backup_enabled_handler_id != 0) {
                Application.settings.disconnect (backup_enabled_handler_id);
                backup_enabled_handler_id = 0;
            }

            if (backup_remote_url_handler_id != 0) {
                Application.settings.disconnect (backup_remote_url_handler_id);
                backup_remote_url_handler_id = 0;
            }
        }

        private void update_backup_action_sensitivity (Gtk.Button sync_now_button, Gtk.Button test_connection_button) {
            bool backup_enabled = Application.settings.get_boolean (KEY_BACKUP_SYNC_ENABLED);
            var remote_url = Application.settings.get_string (KEY_BACKUP_SYNC_REMOTE_URL);
            bool has_remote_url = (remote_url != null && remote_url.strip () != "");
            bool actions_enabled = backup_enabled && has_remote_url;
            sync_now_button.sensitive = actions_enabled;
            test_connection_button.sensitive = actions_enabled;
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
