/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_zoom_tests () {
        /**
         * UC-10.10.10 & UC-20.10.30: Geometry and zoom constants
         */
        GLib.Test.add_func ("/Zoom/UC_20_10_30/ConstantsAndDefaults", () => {
            assert_cmpint (Jots.ZOOM_MIN, GLib.CompareOperator.EQ, 20);
            assert_cmpint (Jots.ZOOM_MAX, GLib.CompareOperator.EQ, 300);
            assert_cmpint (Jots.DEFAULT_ZOOM, GLib.CompareOperator.EQ, 100);
            assert_cmpint (Jots.DEFAULT_WIDTH, GLib.CompareOperator.EQ, 290);
            assert_cmpint (Jots.DEFAULT_HEIGHT, GLib.CompareOperator.EQ, 320);
        });

        /**
         * UC-20.10.31: Scroll delta to ZoomType conversion
         */
        GLib.Test.add_func ("/Zoom/UC_20_10_31/DeltaToZoomType", () => {
            assert_true (Jots.ZoomType.from_delta (0.0) == Jots.ZoomType.NONE);
            assert_true (Jots.ZoomType.from_delta (1.0) == Jots.ZoomType.ZOOM_OUT);
            assert_true (Jots.ZoomType.from_delta (5.5) == Jots.ZoomType.ZOOM_OUT);
            assert_true (Jots.ZoomType.from_delta (-1.0) == Jots.ZoomType.ZOOM_IN);
            assert_true (Jots.ZoomType.from_delta (-3.2) == Jots.ZoomType.ZOOM_IN);
        });

        /**
         * UC-20.10.32: Zoom enum to integer and CSS class roundtrip
         */
        GLib.Test.add_func ("/Zoom/UC_20_10_32/ZoomEnumMappings", () => {
            assert_cmpint (Jots.Zoom.from_int (100).to_int (), GLib.CompareOperator.EQ, 100);
            assert_cmpstr (Jots.Zoom.from_int (100).to_css_class (), GLib.CompareOperator.EQ, "s100");
            assert_cmpint (Jots.Zoom.from_int (20).to_int (), GLib.CompareOperator.EQ, 20);
            assert_cmpstr (Jots.Zoom.from_int (20).to_css_class (), GLib.CompareOperator.EQ, "s20");
            assert_cmpint (Jots.Zoom.from_int (300).to_int (), GLib.CompareOperator.EQ, 300);
            assert_cmpstr (Jots.Zoom.from_int (300).to_css_class (), GLib.CompareOperator.EQ, "s300");
        });
    }
}
