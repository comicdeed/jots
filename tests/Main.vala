/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

public static int main (string[] args) {
    GLib.Test.init (ref args);
    Gtk.init ();

    // Register all Canary test suites
    Jots.Tests.register_git_sync_service_tests ();
    Jots.Tests.register_note_identifier_tests ();
    Jots.Tests.register_note_data_tests ();
    Jots.Tests.register_markdown_storage_tests ();
    Jots.Tests.register_markdown_buffer_tests ();
    Jots.Tests.register_themes_tests ();
    Jots.Tests.register_text_buffer_tests ();
    Jots.Tests.register_zoom_tests ();
    Jots.Tests.register_scribbly_controller_tests ();
    Jots.Tests.register_mcp_protocol_tests ();
    Jots.Tests.register_search_service_tests ();
    Jots.Tests.register_migration_helper_tests ();
    Jots.Tests.register_cheatsheet_tests ();
    Jots.Tests.register_autostart_tests ();
    Jots.Tests.register_markdown_normalizer_tests ();
    Jots.Tests.register_html_to_markdown_tests ();

    return GLib.Test.run ();
}
