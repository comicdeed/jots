/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    public void register_themes_tests () {
        /**
         * UC-50.10.10: Color theme enum, hex color, and CSS class mapping
         */
        GLib.Test.add_func ("/Themes/UC_50_10_10/CssClassMapping", () => {
            assert_cmpstr (Themes.BLUEBERRY.to_css_class (), GLib.CompareOperator.EQ, "blueberry");
            assert_cmpstr (Themes.MINT.to_css_class (), GLib.CompareOperator.EQ, "mint");
            assert_cmpstr (Themes.LIME.to_css_class (), GLib.CompareOperator.EQ, "lime");
            assert_cmpstr (Themes.BANANA.to_css_class (), GLib.CompareOperator.EQ, "banana");
            assert_cmpstr (Themes.ORANGE.to_css_class (), GLib.CompareOperator.EQ, "orange");
            assert_cmpstr (Themes.STRAWBERRY.to_css_class (), GLib.CompareOperator.EQ, "strawberry");
            assert_cmpstr (Themes.BUBBLEGUM.to_css_class (), GLib.CompareOperator.EQ, "bubblegum");
            assert_cmpstr (Themes.GRAPE.to_css_class (), GLib.CompareOperator.EQ, "grape");
            assert_cmpstr (Themes.COCOA.to_css_class (), GLib.CompareOperator.EQ, "cocoa");
            assert_cmpstr (Themes.SLATE.to_css_class (), GLib.CompareOperator.EQ, "slate");
#if LATTE
            assert_cmpstr (Themes.LATTE.to_css_class (), GLib.CompareOperator.EQ, "latte");
#endif
        });

        GLib.Test.add_func ("/Themes/UC_50_10_10/HexColorMapping", () => {
            assert_cmpstr (Themes.BLUEBERRY.to_hex_color (), GLib.CompareOperator.EQ, "#4285f4");
            assert_cmpstr (Themes.MINT.to_hex_color (), GLib.CompareOperator.EQ, "#2ecc71");
            assert_cmpstr (Themes.LIME.to_hex_color (), GLib.CompareOperator.EQ, "#87d322");
            assert_cmpstr (Themes.BANANA.to_hex_color (), GLib.CompareOperator.EQ, "#f6d32d");
            assert_cmpstr (Themes.ORANGE.to_hex_color (), GLib.CompareOperator.EQ, "#ff7800");
            assert_cmpstr (Themes.STRAWBERRY.to_hex_color (), GLib.CompareOperator.EQ, "#ed333b");
            assert_cmpstr (Themes.BUBBLEGUM.to_hex_color (), GLib.CompareOperator.EQ, "#e0569a");
            assert_cmpstr (Themes.GRAPE.to_hex_color (), GLib.CompareOperator.EQ, "#9141ac");
            assert_cmpstr (Themes.COCOA.to_hex_color (), GLib.CompareOperator.EQ, "#865e3c");
            assert_cmpstr (Themes.SLATE.to_hex_color (), GLib.CompareOperator.EQ, "#606f7b");
#if LATTE
            assert_cmpstr (Themes.LATTE.to_hex_color (), GLib.CompareOperator.EQ, "#bfa07a");
#endif

            // Verify each hex color parses cleanly into Gdk.RGBA
            var all_themes = Themes.all ();
            foreach (var t in all_themes) {
                Gdk.RGBA rgba = {};
                assert_true (rgba.parse (t.to_hex_color ()));
            }
        });

        /**
         * UC-50.10.20: Random theme selection
         */
        GLib.Test.add_func ("/Themes/UC_50_10_20/RandomThemeAvoidsDuplicate", () => {
            var valid_themes = Themes.all ();
            for (int i = 0; i < 50; i++) {
                var current = Themes.MINT;
                var next = Themes.random_theme (current);
                assert_true (next != current);
                assert_true ((int)next >= 0 && (int)next < valid_themes.length);
            }
        });
    }
}
