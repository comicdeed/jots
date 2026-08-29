/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {

    public void register_autostart_tests () {

        // ── PackagingContext.detect() ──────────────────────────────────────

        /**
         * UC-60.20.20: FLATPAK_ID set → detect() returns FLATPAK
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_20/DetectFlatpak", () => {
            var saved_appimage = GLib.Environment.get_variable ("APPIMAGE");
            var saved_flatpak = GLib.Environment.get_variable ("FLATPAK_ID");
            GLib.Environment.unset_variable ("APPIMAGE");
            GLib.Environment.set_variable ("FLATPAK_ID", "io.github.comicdeed.jots", true);

            assert (PackagingContext.detect () == PackagingContext.FLATPAK);

            // Restore
            if (saved_flatpak == null) {
                GLib.Environment.unset_variable ("FLATPAK_ID");
            } else {
                GLib.Environment.set_variable ("FLATPAK_ID", saved_flatpak, true);
            }
            if (saved_appimage == null) {
                GLib.Environment.unset_variable ("APPIMAGE");
            } else {
                GLib.Environment.set_variable ("APPIMAGE", saved_appimage, true);
            }
        });

        /**
         * UC-60.20.21: APPIMAGE set (no FLATPAK_ID) → detect() returns APPIMAGE
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_21/DetectAppImage", () => {
            var saved_appimage = GLib.Environment.get_variable ("APPIMAGE");
            var saved_flatpak = GLib.Environment.get_variable ("FLATPAK_ID");
            GLib.Environment.unset_variable ("FLATPAK_ID");
            GLib.Environment.set_variable ("APPIMAGE", "/home/user/Jots-1.2.0-x86_64.AppImage", true);

            assert (PackagingContext.detect () == PackagingContext.APPIMAGE);

            // Restore
            if (saved_flatpak == null) {
                GLib.Environment.unset_variable ("FLATPAK_ID");
            } else {
                GLib.Environment.set_variable ("FLATPAK_ID", saved_flatpak, true);
            }
            if (saved_appimage == null) {
                GLib.Environment.unset_variable ("APPIMAGE");
            } else {
                GLib.Environment.set_variable ("APPIMAGE", saved_appimage, true);
            }
        });

        /**
         * UC-60.20.22: Neither FLATPAK_ID nor APPIMAGE set → detect() returns NATIVE
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_22/DetectNative", () => {
            var saved_appimage = GLib.Environment.get_variable ("APPIMAGE");
            var saved_flatpak = GLib.Environment.get_variable ("FLATPAK_ID");
            GLib.Environment.unset_variable ("FLATPAK_ID");
            GLib.Environment.unset_variable ("APPIMAGE");

            assert (PackagingContext.detect () == PackagingContext.NATIVE);

            // Restore
            if (saved_flatpak == null) {
                GLib.Environment.unset_variable ("FLATPAK_ID");
            } else {
                GLib.Environment.set_variable ("FLATPAK_ID", saved_flatpak, true);
            }
            if (saved_appimage == null) {
                GLib.Environment.unset_variable ("APPIMAGE");
            } else {
                GLib.Environment.set_variable ("APPIMAGE", saved_appimage, true);
            }
        });

        // ── PackagingContext.get_exec_command() ───────────────────────────

        /**
         * UC-60.20.23: APPIMAGE context → get_exec_command() returns the AppImage path
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_23/ExecCommandAppImage", () => {
            var appimage_path = "/home/user/Jots-1.2.0-x86_64.AppImage";
            var saved = GLib.Environment.get_variable ("APPIMAGE");
            GLib.Environment.set_variable ("APPIMAGE", appimage_path, true);

            var cmd = PackagingContext.APPIMAGE.get_exec_command ("io.github.comicdeed.jots");
            assert_cmpstr (cmd, GLib.CompareOperator.EQ, appimage_path);

            // Restore
            if (saved == null) {
                GLib.Environment.unset_variable ("APPIMAGE");
            } else {
                GLib.Environment.set_variable ("APPIMAGE", saved, true);
            }
        });

        /**
         * UC-60.20.24: NATIVE context → get_exec_command() returns the app-id
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_24/ExecCommandNative", () => {
            var cmd = PackagingContext.NATIVE.get_exec_command ("io.github.comicdeed.jots");
            assert_cmpstr (cmd, GLib.CompareOperator.EQ, "io.github.comicdeed.jots");
        });

        /**
         * UC-60.20.25: FLATPAK context → get_exec_command() returns "flatpak run <app_id>"
         */
        GLib.Test.add_func ("/Autostart/PackagingContext/UC_60_20_25/ExecCommandFlatpak", () => {
            var saved_flatpak = GLib.Environment.get_variable ("FLATPAK_ID");

            GLib.Environment.set_variable ("FLATPAK_ID", "io.github.comicdeed.jots", true);
            var cmd = PackagingContext.FLATPAK.get_exec_command ("io.github.comicdeed.jots");
            assert_cmpstr (cmd, GLib.CompareOperator.EQ, "flatpak run io.github.comicdeed.jots");

            // Restore
            if (saved_flatpak != null) {
                GLib.Environment.set_variable ("FLATPAK_ID", saved_flatpak, true);
            } else {
                GLib.Environment.unset_variable ("FLATPAK_ID");
            }
        });

        // ── autostart_desktop_path() / filesystem ground truth ────────────

        /**
         * UC-60.20.26: autostart_desktop_path() builds the correct canonical path
         * UC-60.20.27: FileUtils correctly reports presence/absence of the .desktop file
         */
        GLib.Test.add_func ("/Autostart/IsActive/UC_60_20_26_27/FilesystemGroundTruth", () => {
            // UC-60.20.26: verify path formula matches XDG spec
            var expected = GLib.Path.build_filename (
                GLib.Environment.get_user_config_dir (),
                "autostart",
                APP_ID + ".desktop"
            );
            var actual = Jots.autostart_desktop_path (APP_ID);
            assert_cmpstr (actual, GLib.CompareOperator.EQ, expected);

            // UC-60.20.27: write the file and confirm FileUtils detects it, then remove
            var autostart_dir = GLib.Path.build_filename (
                GLib.Environment.get_user_config_dir (), "autostart");
            GLib.DirUtils.create_with_parents (autostart_dir, 0755);

            // Use a sentinel test file so we don't corrupt a real autostart entry
            var test_desktop_path = GLib.Path.build_filename (
                autostart_dir, "jots-test-sentinel.desktop");

            // Absent by default
            assert_false (GLib.FileUtils.test (test_desktop_path, GLib.FileTest.EXISTS));

            // Create → present
            try {
                GLib.FileUtils.set_contents (test_desktop_path, "[Desktop Entry]\nType=Application\n");
            } catch (GLib.FileError e) {
                GLib.Test.fail_printf ("Could not write sentinel desktop file: %s", e.message);
            }
            assert_true (GLib.FileUtils.test (test_desktop_path, GLib.FileTest.EXISTS));

            // Cleanup
            GLib.FileUtils.unlink (test_desktop_path);
            assert_false (GLib.FileUtils.test (test_desktop_path, GLib.FileTest.EXISTS));
        });
    }
}
