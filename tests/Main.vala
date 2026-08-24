/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

public static int main (string[] args) {
    GLib.Test.init (ref args);
    Gtk.init ();

    // Register all Canary test suites
    Jots.Tests.register_note_data_tests ();
    Jots.Tests.register_markdown_storage_tests ();
    Jots.Tests.register_markdown_buffer_tests ();
    Jots.Tests.register_themes_tests ();
    Jots.Tests.register_text_buffer_tests ();
    Jots.Tests.register_zoom_tests ();
    Jots.Tests.register_mcp_protocol_tests ();

    return GLib.Test.run ();
}
