/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    public void register_themes_tests () {
        /**
         * UC-50.10.10: Color theme enum and CSS class mapping
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
