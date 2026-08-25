/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

namespace Jots {

    public class PreferencesView : Granite.Bin {

        private Granite.Toast toast;
        public Gtk.Button close_button;

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

            toast = new Granite.Toast ("");
            overlay.add_overlay (toast);
            child = overlay;

            // the box with all the settings
            var settingsbox = new Gtk.Box (VERTICAL, SPACING_DOUBLE) {
                hexpand = true,
                vexpand = true,
                valign = Gtk.Align.START
            };

            /***************************************/
            /*               lists                 */
            /***************************************/

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

            settingsbox.append (lists_box);

            /*************************************************/
            /*              scribbly Toggle                  */
            /*************************************************/

            var scribbly_toggle = new Gtk.Switch ();

            Application.settings.bind (KEY_SCRIBBLY,
                scribbly_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var scribbly_box = new Jots.SettingsBox (
                _("Scribble unfocused notes (Ctrl+H)"),
                null,
                scribbly_toggle
            );

            settingsbox.append (scribbly_box);

            /*************************************************/
            /*               hidebar Toggle                  */
            /*************************************************/
            var hidebar_toggle = new Gtk.Switch ();

            Application.settings.bind (KEY_HIDEBAR,
                hidebar_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var hidebar_box = new Jots.SettingsBox (
                _("Hide bottom bar (Ctrl+T)"),
                null,
                hidebar_toggle
            );

            settingsbox.append (hidebar_box);

            /*************************************************/
            /*               Typography Settings             */
            /*************************************************/
            var custom_fonts_toggle = new Gtk.Switch ();
            Application.settings.bind (KEY_CUSTOM_FONTS,
                custom_fonts_toggle, "active",
                GLib.SettingsBindFlags.DEFAULT);

            var custom_fonts_box = new Jots.SettingsBox (
                _("Use custom fonts"),
                _("Override system default fonts for sticky notes"),
                custom_fonts_toggle
            );
            settingsbox.append (custom_fonts_box);

            // Default Note Font
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
            settingsbox.append (default_font_box);

            // Monospace Note Font (with monospace-only filtering)
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
            settingsbox.append (mono_font_box);

            custom_fonts_toggle.bind_property ("active", default_font_btn, "sensitive", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
            custom_fonts_toggle.bind_property ("active", mono_font_btn, "sensitive", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

            /***********************************************/
            /*               Restore_last                  */
            /***********************************************/

            var restore_button = new Gtk.Button () {
                label = _("Restore note"),
                tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Ctrl>R"},
                    _("Restore the last deleted sticky note")
                ),
                action_name = Application.ACTION_PREFIX + Application.ACTION_RESTORE_LAST,
                width_request = 96,
            };

            /****************************************************/
            /*               Autostart Request                  */
            /****************************************************/

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

            settingsbox.append (autostart_box);
#endif

            /*************************************************/
            // Bar at the bottom
            var actionbar = new Gtk.CenterBox () {
                valign = Gtk.Align.END,
                margin_top = SPACING_TRIPLE + SPACING_DOUBLE,
                hexpand = true,
                vexpand = false
            };

            actionbar.start_widget = new Gtk.LinkButton.with_label (
                DONATE_LINK,
                _("Support us!")
            );

            var right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, Jots.SPACING_DOUBLE);
            actionbar.end_widget = right_box;

            var close = new Gtk.Button () {
                action_name = "window.close",
                width_request = 96,
                label = _("Close"),
                tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Alt>F4"},
                    _("Close preferences")
                )
            };
            right_box.append (restore_button);
            right_box.append (close);

            prefview.append (settingsbox);
            prefview.append (actionbar);
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
