/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {
    /**
     * Client-side D-Bus proxy interface for the native Jots NoteService.
     */
    [DBus (name = "io.github.comicdeed.jots.Notes")]
    public interface NotesProxy : GLib.Object {
        public abstract string list_notes () throws GLib.Error;
        public abstract string get_note (string id) throws GLib.Error;
        public abstract string create_note (string? title, string? content, string? theme) throws GLib.Error;
        public abstract string update_note (string id, string? title, string? content, string? theme) throws GLib.Error;
        public abstract bool delete_note (string id) throws GLib.Error;
        public abstract string search_notes (string query) throws GLib.Error;
        public abstract string ping () throws GLib.Error;
    }
}
