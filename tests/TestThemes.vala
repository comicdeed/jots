/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_themes_tests () {
        /**
         * UC-50.10.10: Color theme enum, hex color, and CSS class mapping
         */
        GLib.Test.add_func ("/Themes/UC_50_10_10/CssClassMapping", () => {
            assert_cmpstr (Themes.BANANA.to_css_class (), GLib.CompareOperator.EQ, "banana");
            assert_cmpstr (Themes.TANGERINE.to_css_class (), GLib.CompareOperator.EQ, "tangerine");
            assert_cmpstr (Themes.PEACH.to_css_class (), GLib.CompareOperator.EQ, "peach");
            assert_cmpstr (Themes.WATERMELON.to_css_class (), GLib.CompareOperator.EQ, "watermelon");
            assert_cmpstr (Themes.BUBBLEGUM.to_css_class (), GLib.CompareOperator.EQ, "bubblegum");
            assert_cmpstr (Themes.LAVENDER.to_css_class (), GLib.CompareOperator.EQ, "lavender");
            assert_cmpstr (Themes.OCEAN.to_css_class (), GLib.CompareOperator.EQ, "ocean");
            assert_cmpstr (Themes.SEA_GLASS.to_css_class (), GLib.CompareOperator.EQ, "sea_glass");
            assert_cmpstr (Themes.MINT.to_css_class (), GLib.CompareOperator.EQ, "mint");
            assert_cmpstr (Themes.PEAR.to_css_class (), GLib.CompareOperator.EQ, "pear");
            assert_cmpstr (Themes.PEBBLE.to_css_class (), GLib.CompareOperator.EQ, "pebble");
            assert_cmpstr (Themes.GRAPHITE.to_css_class (), GLib.CompareOperator.EQ, "graphite");
        });

        GLib.Test.add_func ("/Themes/UC_50_10_10/HexColorMapping", () => {
            assert_cmpstr (Themes.BANANA.to_hex_color (), GLib.CompareOperator.EQ, "#FFB300");
            assert_cmpstr (Themes.TANGERINE.to_hex_color (), GLib.CompareOperator.EQ, "#FF6D00");
            assert_cmpstr (Themes.PEACH.to_hex_color (), GLib.CompareOperator.EQ, "#FF5252");
            assert_cmpstr (Themes.WATERMELON.to_hex_color (), GLib.CompareOperator.EQ, "#D50000");
            assert_cmpstr (Themes.BUBBLEGUM.to_hex_color (), GLib.CompareOperator.EQ, "#F50057");
            assert_cmpstr (Themes.LAVENDER.to_hex_color (), GLib.CompareOperator.EQ, "#AA00FF");
            assert_cmpstr (Themes.OCEAN.to_hex_color (), GLib.CompareOperator.EQ, "#2979FF");
            assert_cmpstr (Themes.SEA_GLASS.to_hex_color (), GLib.CompareOperator.EQ, "#00BFA5");
            assert_cmpstr (Themes.MINT.to_hex_color (), GLib.CompareOperator.EQ, "#00C853");
            assert_cmpstr (Themes.PEAR.to_hex_color (), GLib.CompareOperator.EQ, "#AEEA00");
            assert_cmpstr (Themes.PEBBLE.to_hex_color (), GLib.CompareOperator.EQ, "#9E9E9E");
            assert_cmpstr (Themes.GRAPHITE.to_hex_color (), GLib.CompareOperator.EQ, "#546E7A");

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

        /**
         * UC-50.10.30: Deprecated pre-1.x color name aliases and unrecognized-name fallback
         */
        GLib.Test.add_func ("/Themes/UC_50_10_30/DeprecatedAliasesResolveToNewEquivalents", () => {
            assert_true (Themes.from_string ("blueberry") == Themes.OCEAN);
            assert_true (Themes.from_string ("lime") == Themes.PEAR);
            assert_true (Themes.from_string ("orange") == Themes.TANGERINE);
            assert_true (Themes.from_string ("strawberry") == Themes.WATERMELON);
            assert_true (Themes.from_string ("grape") == Themes.LAVENDER);
            assert_true (Themes.from_string ("cocoa") == Themes.GRAPHITE);
            assert_true (Themes.from_string ("slate") == Themes.PEBBLE);
            assert_true (Themes.from_string ("latte") == Themes.PEACH);
        });

        GLib.Test.add_func ("/Themes/UC_50_10_30/UnrecognizedNameFallsBackToPebble", () => {
            assert_true (Themes.from_string ("not-a-real-color") == Themes.PEBBLE);
            assert_true (Themes.from_string (null) == Themes.PEBBLE);
        });

        /**
         * UC-50.10.40: Legacy numeric ordinal (pre-1.x `color:` field / Jorts JSON import)
         */
        GLib.Test.add_func ("/Themes/UC_50_10_40/LegacyOrdinalResolvesToNewEquivalents", () => {
            assert_true (Themes.from_legacy_ordinal (0) == Themes.OCEAN);      // Blueberry
            assert_true (Themes.from_legacy_ordinal (1) == Themes.MINT);      // Mint
            assert_true (Themes.from_legacy_ordinal (2) == Themes.PEAR);      // Lime
            assert_true (Themes.from_legacy_ordinal (3) == Themes.BANANA);    // Banana
            assert_true (Themes.from_legacy_ordinal (4) == Themes.TANGERINE); // Orange
            assert_true (Themes.from_legacy_ordinal (5) == Themes.WATERMELON); // Strawberry
            assert_true (Themes.from_legacy_ordinal (6) == Themes.BUBBLEGUM); // Bubblegum
            assert_true (Themes.from_legacy_ordinal (7) == Themes.LAVENDER); // Grape
            assert_true (Themes.from_legacy_ordinal (8) == Themes.GRAPHITE); // Cocoa
            assert_true (Themes.from_legacy_ordinal (9) == Themes.PEBBLE);   // Slate
            assert_true (Themes.from_legacy_ordinal (10) == Themes.PEACH);   // Latte
            assert_true (Themes.from_legacy_ordinal (99) == Themes.PEBBLE);  // out of range fallback
        });
    }
}
