/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * Detects the active packaging context at runtime and resolves the
     * correct launch command for autostart registration and MCP error guidance.
     *
     * Detection priority (these are mutually exclusive in practice):
     *   1. Flatpak  — FLATPAK_ID env var is set by the Flatpak runtime
     *   2. AppImage — APPIMAGE env var is set by the AppRun script before exec
     *   3. Native   — neither is set; APP_ID binary is expected on PATH
     */
    public enum PackagingContext {
        FLATPAK,
        APPIMAGE,
        NATIVE;

        public static PackagingContext detect () {
            if (GLib.Environment.get_variable ("FLATPAK_ID") != null) {
                return FLATPAK;
            }
            if (GLib.Environment.get_variable ("APPIMAGE") != null) {
                return APPIMAGE;
            }
            return NATIVE;
        }

        /**
         * Returns the correct Exec= command string for this packaging context.
         *
         * Used for:
         *   - Writing XDG autostart .desktop files (AppImage/Native)
         *   - Emitting actionable launch instructions in MCP error messages
         *
         * Returns null only if context is APPIMAGE but the APPIMAGE env var is
         * unexpectedly empty — defensive guard, should never occur in practice.
         */
        public string? get_exec_command (string app_id) {
            switch (this) {
                case FLATPAK:
                    var flatpak_id = GLib.Environment.get_variable ("FLATPAK_ID");
                    return "flatpak run " + ((flatpak_id != null && flatpak_id.strip () != "") ? flatpak_id : app_id);
                case APPIMAGE:
                    var appimage_path = GLib.Environment.get_variable ("APPIMAGE");
                    return (appimage_path != null && appimage_path.strip () != "") ? appimage_path : app_id;
                case NATIVE:
                default:
                    return app_id;
            }
        }
    }

    /**
     * Returns the canonical XDG autostart .desktop file path for this app_id.
     * Lives in PackagingContext.vala (no libportal dependency) so it can be
     * used by both Autostart.vala and tests.
     */
    public static string autostart_desktop_path (string app_id) {
        return GLib.Path.build_filename (
            GLib.Environment.get_user_config_dir (),
            "autostart",
            app_id + ".desktop"
        );
    }
}
