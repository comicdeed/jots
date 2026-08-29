/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

public class Jots.Autostart {

    // ── File path helper ──────────────────────────────────────────────────

    private static string autostart_dir () {
        return GLib.Path.build_filename (
            GLib.Environment.get_user_config_dir (),
            "autostart"
        );
    }

    private static string autostart_path () {
        return Jots.autostart_desktop_path (APP_ID);
    }

    // ── Public API ────────────────────────────────────────────────────────

    public async void request_set () {
        var ctx = PackagingContext.detect ();
        if (ctx == PackagingContext.FLATPAK) {
            yield portal_request_set ();
        } else {
            write_xdg_desktop_file ();
        }
    }

    public async void request_remove () {
        var ctx = PackagingContext.detect ();
        if (ctx == PackagingContext.FLATPAK) {
            yield portal_request_remove ();
        } else {
            delete_xdg_desktop_file ();
        }
    }

    /**
     * Reads the filesystem (not GSettings) to determine whether autostart
     * is actually registered. Called at startup to sync the UI toggle to
     * ground truth.
     */
    public static bool is_active () {
        return GLib.FileUtils.test (autostart_path (), GLib.FileTest.EXISTS);
    }

    // ── Flatpak path: delegate to libportal ───────────────────────────────

    Xdp.Portal portal;
    GenericArray<weak string> cmd;

    private void ensure_portal () {
        if (portal == null) {
            portal = new Xdp.Portal ();
            cmd = new GenericArray<weak string> ();
            cmd.add (APP_ID);
        }
    }

    private async void portal_request_set () {
        ensure_portal ();
        try {
            var result = yield portal.request_background (
                null,
                _ ("Set Jots to start with the computer"),
                cmd,
                Xdp.BackgroundFlags.AUTOSTART,
                null);
            debug ("Autostart portal set: %b", result);
        } catch (Error e) {
            warning ("Autostart portal request_set failed: %s", e.message);
        }
    }

    private async void portal_request_remove () {
        ensure_portal ();
        try {
            var result = yield portal.request_background (
                null,
                _ ("Remove Jots from system autostart"),
                cmd,
                Xdp.BackgroundFlags.NONE,
                null);
            debug ("Autostart portal remove: %b", result);
        } catch (Error e) {
            warning ("Autostart portal request_remove failed: %s", e.message);
        }
    }

    // ── Non-Flatpak path: write XDG Autostart .desktop directly ──────────

    private void write_xdg_desktop_file () {
        var exec_cmd = PackagingContext.detect ().get_exec_command (APP_ID);
        if (exec_cmd == null || exec_cmd.strip () == "") {
            warning ("Autostart: could not determine exec command for this packaging context; autostart not set.");
            return;
        }

        GLib.DirUtils.create_with_parents (autostart_dir (), 0755);

        var content = "[Desktop Entry]\nType=Application\nName=Jots\nExec=%s\nIcon=%s\nTerminal=false\nHidden=false\nComment=Sticky notes application\n".printf (exec_cmd, APP_ID);

        try {
            GLib.FileUtils.set_contents (autostart_path (), content);
            debug ("Autostart: wrote %s", autostart_path ());
        } catch (GLib.FileError e) {
            warning ("Autostart: failed to write desktop file: %s", e.message);
        }
    }

    private void delete_xdg_desktop_file () {
        var path = autostart_path ();
        if (!GLib.FileUtils.test (path, GLib.FileTest.EXISTS)) {
            return;
        }
        if (GLib.FileUtils.unlink (path) != 0) {
            warning ("Autostart: failed to remove %s", path);
        } else {
            debug ("Autostart: removed %s", path);
        }
    }
}
