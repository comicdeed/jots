/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
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
    }
}
