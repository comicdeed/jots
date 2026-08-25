/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    public void register_scribbly_controller_tests () {
        /**
         * UC-60.10.10: ScribblyController initializes according to GSettings and responds to changes
         */
        GLib.Test.add_func ("/ScribblyController/UC_60_10_10/ScribbleStateTransitions", () => {
            var window = new Gtk.Window ();
            var controller = new Jots.ScribblyController (window);

            // Initially false
            controller.scribble = false;
            assert_false (window.has_css_class ("scribbled"));
            assert_false (window.has_css_class ("is-unfocused"));

            // Toggle scribble on while window is not active
            controller.scribble = true;
            assert_true (window.has_css_class ("scribbled"));
            assert_true (window.has_css_class ("is-unfocused"));

            // Toggle scribble off
            controller.scribble = false;
            assert_false (window.has_css_class ("scribbled"));
            assert_false (window.has_css_class ("is-unfocused"));
        });

        /**
         * UC-60.10.20: Redacted Script font presence in Pango FontMap
         */
        GLib.Test.add_func ("/ScribblyController/UC_60_10_20/RedactedScriptFontAvailability", () => {
            var font_map = Pango.CairoFontMap.get_default ();
            bool found = false;
            Pango.FontFamily[] families;
            font_map.list_families (out families);
            foreach (var family in families) {
                if (family.get_name () == "Redacted Script") {
                    found = true;
                    break;
                }
            }
            assert_true (found);
        });
    }
}
