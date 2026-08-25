/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots {

    /**
     * Manages global typography customization and dynamic CSS font application.
     */
    public class FontController : Object {

        private Gtk.CssProvider css_provider;
        private GLib.Settings? settings;

        public FontController () {
            css_provider = new Gtk.CssProvider ();

            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.add_provider_for_display (
                    display,
                    css_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 2
                );
            }

            init_settings ();

            if (settings != null) {
                settings.changed[KEY_CUSTOM_FONTS].connect (update_fonts);
                settings.changed[KEY_DEFAULT_FONT].connect (update_fonts);
                settings.changed[KEY_MONOSPACE_FONT].connect (update_fonts);
            }

            update_fonts ();
        }

        private void init_settings () {
            var schema_source = GLib.SettingsSchemaSource.get_default ();
            if (schema_source != null && schema_source.lookup ("io.github.comicdeed.jots.devel", true) != null) {
                try {
                    settings = new GLib.Settings ("io.github.comicdeed.jots.devel");
                } catch (GLib.Error e) {
                    debug ("Could not load GSettings in FontController: %s", e.message);
                }
            }
        }

        /**
         * Regenerates the dynamic font CSS based on current GSettings.
         */
        public void update_fonts () {
            if (settings == null) {
                return;
            }

            var use_custom = settings.get_boolean (KEY_CUSTOM_FONTS);
            if (!use_custom) {
                css_provider.load_from_string ("");
                return;
            }

            var default_desc_str = settings.get_string (KEY_DEFAULT_FONT);
            var mono_desc_str = settings.get_string (KEY_MONOSPACE_FONT);

            var sb = new StringBuilder ();

            if (default_desc_str.strip () != "") {
                var desc = Pango.FontDescription.from_string (default_desc_str);
                var family = desc.get_family ();
                if (family != null && family.strip () != "") {
                    sb.append_printf ("textview.view, editablelabel { font-family: \"%s\", sans-serif; }\n", family);
                }
            }

            if (mono_desc_str.strip () != "") {
                var mono_desc = Pango.FontDescription.from_string (mono_desc_str);
                var mono_family = mono_desc.get_family ();
                if (mono_family != null && mono_family.strip () != "") {
                    sb.append_printf ("textview.view.monospace, editablelabel.monospace, .monospace, .monospace textview.view { font-family: \"%s\", monospace; }\n", mono_family);
                }
            }

            css_provider.load_from_string (sb.str);
            debug ("Updated typography CSS: %s", sb.str);
        }

        /**
         * Query the desktop system default interface font.
         */
        public static string get_system_default_font () {
            var schema_source = GLib.SettingsSchemaSource.get_default ();
            if (schema_source != null && schema_source.lookup ("org.gnome.desktop.interface", true) != null) {
                var iface_settings = new GLib.Settings ("org.gnome.desktop.interface");
                var font_name = iface_settings.get_string ("font-name");
                if (font_name != null && font_name.strip () != "") {
                    return font_name;
                }
            }
            return "Sans 11";
        }

        /**
         * Query the desktop system monospace font.
         */
        public static string get_system_monospace_font () {
            var schema_source = GLib.SettingsSchemaSource.get_default ();
            if (schema_source != null && schema_source.lookup ("org.gnome.desktop.interface", true) != null) {
                var iface_settings = new GLib.Settings ("org.gnome.desktop.interface");
                var mono_name = iface_settings.get_string ("monospace-font-name");
                if (mono_name != null && mono_name.strip () != "") {
                    return mono_name;
                }
            }
            return "Monospace 10";
        }

        /**
         * Query the currently active monospace font family name.
         */
        public static string get_active_monospace_family () {
            var schema_source = GLib.SettingsSchemaSource.get_default ();
            if (schema_source != null && schema_source.lookup ("io.github.comicdeed.jots.devel", true) != null) {
                try {
                    var s = new GLib.Settings ("io.github.comicdeed.jots.devel");
                    if (s.get_boolean (KEY_CUSTOM_FONTS)) {
                        var mono_str = s.get_string (KEY_MONOSPACE_FONT);
                        if (mono_str.strip () != "") {
                            var desc = Pango.FontDescription.from_string (mono_str);
                            var fam = desc.get_family ();
                            if (fam != null && fam.strip () != "") {
                                return fam;
                            }
                        }
                    }
                } catch (GLib.Error e) {}
            }
            var sys_mono = get_system_monospace_font ();
            var sys_desc = Pango.FontDescription.from_string (sys_mono);
            var sys_fam = sys_desc.get_family ();
            if (sys_fam != null && sys_fam.strip () != "") {
                return sys_fam;
            }
            return "Monospace";
        }

        /**
         * Helper to reset fonts to system defaults.
         */
        public static void reset_to_defaults () {
            var schema_source = GLib.SettingsSchemaSource.get_default ();
            if (schema_source != null && schema_source.lookup ("io.github.comicdeed.jots.devel", true) != null) {
                try {
                    var s = new GLib.Settings ("io.github.comicdeed.jots.devel");
                    s.set_boolean (KEY_CUSTOM_FONTS, false);
                    s.set_string (KEY_DEFAULT_FONT, "");
                    s.set_string (KEY_MONOSPACE_FONT, "");
                } catch (GLib.Error e) {}
            }
        }
    }
}
