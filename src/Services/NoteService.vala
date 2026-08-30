/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {
    /**
     * Native D-Bus Service Interface for note management and desktop automation.
     * Exposes high-level note query, mutation, and search operations on the session bus.
     */
    [DBus (name = "io.github.comicdeed.jots.Notes")]
    public class NoteService : GLib.Object {
        private NoteManager note_manager;

        public NoteService (NoteManager manager) {
            this.note_manager = manager;
        }

        /**
         * List all active notes as a JSON array string
         */
        public string list_notes () throws GLib.Error {
            debug ("NoteService: list_notes called");
            return note_manager.get_all_notes_json_string ();
        }

        /**
         * Retrieve a single note by UUID
         */
        public string get_note (string id) throws GLib.Error {
            debug ("NoteService: get_note called for '%s'", id);
            var note = note_manager.get_note_by_id (id);
            if (note == null) {
                throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
            }
            return note.to_json_string ();
        }

        /**
         * Create a new note with given properties
         */
        public string create_note (string? title, string? content, string? theme) throws GLib.Error {
            debug ("NoteService: create_note called");
            var note = note_manager.create_note_with_properties (title, content, theme);
            return note.to_json_string ();
        }

        /**
         * Update an existing note with new properties
         */
        public string update_note (string id, string? title, string? content, string? theme) throws GLib.Error {
            debug ("NoteService: update_note called for '%s'", id);
            var note = note_manager.update_note_by_id (id, title, content, theme);
            return note.to_json_string ();
        }

        /**
         * Delete an active note by UUID
         */
        public bool delete_note (string id) throws GLib.Error {
            debug ("NoteService: delete_note called for '%s'", id);
            bool deleted = note_manager.delete_note_by_id (id);
            if (!deleted) {
                throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
            }
            return true;
        }

        /**
         * Search active notes by keyword query
         */
        public string search_notes (string query) throws GLib.Error {
            debug ("NoteService: search_notes called for query '%s'", query);
            if (query.length > MAX_NOTE_TITLE_LENGTH) {
                throw new GLib.IOError.INVALID_ARGUMENT ("Search query exceeds maximum length of %d characters.", MAX_NOTE_TITLE_LENGTH);
            }
            return note_manager.search_notes_json_string (query);
        }

        /**
         * Liveness check
         */
        public string ping () throws GLib.Error {
            return "pong";
        }
    }
}
