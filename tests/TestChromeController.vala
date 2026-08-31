/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {

    public void register_chrome_controller_tests () {
        /**
         * UC-50.30.10: Focus-aware actionbar reveal and hide transitions
         */
        GLib.Test.add_func ("/ChromeController/UC_50_30_10/FocusRevealAndHide", () => {
            var window = new Gtk.Window ();
            var actionbar = new Gtk.ActionBar ();
            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            root.append (actionbar);
            window.set_child (root);

            var controller = new Jots.ChromeController (window, actionbar, root);

            // With autohide = true and inactive window, actionbar is hidden
            controller.autohide = true;
            assert_false (controller.is_chrome_revealed);

            // With autohide = false, actionbar is revealed even when inactive
            controller.autohide = false;
            assert_true (controller.is_chrome_revealed);

            // Toggle autohide back on
            controller.autohide = true;
            assert_false (controller.is_chrome_revealed);

            controller.dispose ();
        });

        /**
         * UC-50.30.20: Active popover override keeps actionbar revealed
         */
        GLib.Test.add_func ("/ChromeController/UC_50_30_20/PopoverOverride", () => {
            var window = new Gtk.Window ();
            var actionbar = new Gtk.ActionBar ();
            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            root.append (actionbar);
            window.set_child (root);

            var controller = new Jots.ChromeController (window, actionbar, root);
            controller.autohide = true;

            // Inactive window -> hidden
            assert_false (controller.is_chrome_revealed);

            // Popover opened -> revealed
            controller.set_popover_active (true);
            assert_true (controller.is_chrome_revealed);

            // Popover closed -> hidden again
            controller.set_popover_active (false);
            assert_false (controller.is_chrome_revealed);

            controller.dispose ();
        });

        /**
         * UC-50.30.30: Hover delay cancellation on mouse exit
         */
        GLib.Test.add_func ("/ChromeController/UC_50_30_30/HoverCancellation", () => {
            var window = new Gtk.Window ();
            var actionbar = new Gtk.ActionBar ();
            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            root.append (actionbar);
            window.set_child (root);

            var controller = new Jots.ChromeController (window, actionbar, root);
            controller.autohide = true;

            assert_false (controller.is_chrome_revealed);
            controller.update_visibility ();
            assert_false (controller.is_chrome_revealed);

            controller.dispose ();
        });
    }
}
