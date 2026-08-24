/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

/**
* Responsible for keeping track of various Sticky Notes windows
* It does its thing on its own. Make sure to call init() to summon all notes from storage
*/
public class Jots.NoteManager : Object {

    private static uint debounce_timer_id;
    private static bool saving_lock = true;
    private static NoteData? last_deleted = null;

    private Jots.Application application;
    public Gee.ArrayList<StickyNoteWindow> open_notes;
    public Jots.Storage storage;

    public NoteManager (Jots.Application app) {
        this.application = app;
    }

    construct {
        open_notes = new Gee.ArrayList<StickyNoteWindow> ();
        storage = new Jots.Storage ();
    }

    /*************************************************/
    /**
    * Retrieve data from storage, and loop through it to create notes
    * Keep an active list of Windows.
    * We do not do this at construct time so we stay flexible whenever we want to init
    * NoteManager is also created too early by the app for new windows
    */
    private bool is_initialized = false;

    public void ensure_initialized () {
        if (is_initialized) {
            return;
        }
        init ();
    }

    public void init () {
        if (is_initialized) {
            return;
        }
        debug ("Opening all sticky notes now!");
        Json.Array loaded_data = storage.load ();

        if (loaded_data.get_length () == 0) {
            var note_data = new NoteData ();
            note_data.theme = DEFAULT_THEME;

            print ("\nNo note in storage! Let's create a new one");
            create_note (note_data);

        } else {
            foreach (var json_data in loaded_data.get_elements ()) {
                var json_obj = json_data.dup_object ();
                var note_data = new NoteData.from_json (json_obj);

                print ("\nLoaded: " + note_data.title);
                create_note (note_data);
            }
        }

        saving_lock = false;
        is_initialized = true;
    }

    /*************************************************/
    /**
    * Create new instances of StickyNoteWindow
    * Should we have data, we can pass it off, else create from random data
    * If we have data, nice, just load it into a new instance. Else we do a lil new note
    */
    public void create_note (NoteData? data = null) {
        debug ("Lets do a note");
        Jots.StickyNoteWindow note;

        if (data != null) {
            note = new StickyNoteWindow (application, data);

        } else {
            var random_data = new NoteData ();

            // One chance at the golden sticky
            random_data = Jots.Utils.golden_sticky (random_data);
            note = new StickyNoteWindow (application, random_data);
        }

        /* LETSGO */
        open_notes.add (note);

        note.show ();
        note.present ();
    }

    /*************************************************/
    /**
    * Delete a note by remove it from the active list and closing its window
    */
    public void delete_note (StickyNoteWindow note) {
        debug ("Removing a note…");

        last_deleted = note.packaged ();

        var action_restore = application.lookup_action (Application.ACTION_RESTORE_LAST);
        ((SimpleAction)action_restore).set_enabled (true);

        open_notes.remove (note);
        application.remove_window ((Gtk.Window)note);

        note.close ();

        immediately_save ();
    }

    /*************************************************/
    /**
    * Cue to immediately write from the active list to the storage
    */
    public void save_all () {
        debug ("Save the stickies!");
        if (saving_lock) {return;}

        if (debounce_timer_id != 0) {
            GLib.Source.remove (debounce_timer_id);
        }

        debounce_timer_id = Timeout.add (DEBOUNCE, debounce_handler);
    }

    public bool debounce_handler () {
        debounce_timer_id = 0;
        immediately_save ();
        return GLib.Source.REMOVE;
    }

    public void immediately_save () {
        var array = new Json.Array ();

        foreach (Jots.StickyNoteWindow note in open_notes) {
            var data = note.packaged ();
            var object = data.to_json ();
            array.add_object_element (object);
        };

        storage.save (array);
    }

    public void new_note () {
        debug ("New Note");
        create_note ();
    }

    public void restore_last_deleted () {
        debug ("Restoring last deleted");

        if (last_deleted == null) {
            return;
        }

        create_note (last_deleted);

        var action_restore = application.lookup_action (Application.ACTION_RESTORE_LAST);
        ((SimpleAction)action_restore).set_enabled (false);

        last_deleted = null;
    }

    /*************************************************/
    /*         MCP & IPC MANAGEMENT METHODS          */
    /*************************************************/

    /**
    * Find an active StickyNoteWindow by note UUID
    */
    public StickyNoteWindow? get_window_by_id (string id) {
        ensure_initialized ();
        foreach (var note in open_notes) {
            if (note.note_id == id) {
                return note;
            }
        }
        return null;
    }

    /**
    * Get NoteData by UUID
    */
    public NoteData? get_note_by_id (string id) {
        var win = get_window_by_id (id);
        if (win != null) {
            return win.packaged ();
        }
        return null;
    }

    /**
    * Return all active notes serialized as a JSON array string
    */
    public string get_all_notes_json_string () {
        ensure_initialized ();
        var array = new Json.Array ();
        foreach (var note in open_notes) {
            array.add_object_element (note.packaged ().to_json ());
        }
        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        var gen = new Json.Generator ();
        gen.set_root (node);
        return gen.to_data (null);
    }

    /**
    * Create a new note with properties, enforcing content and window guardrails
    */
    public NoteData create_note_with_properties (string? title, string? content, string? theme_name) throws GLib.Error {
        ensure_initialized ();
        if (open_notes.size >= MAX_ACTIVE_NOTES) {
            throw new GLib.IOError.FAILED ("Maximum active notes limit reached (%d). Please delete or clean up unused notes.", MAX_ACTIVE_NOTES);
        }

        if (content != null && content.length > MAX_NOTE_CONTENT_LENGTH) {
            throw new GLib.IOError.INVALID_ARGUMENT ("Content exceeds maximum length of %d characters.", MAX_NOTE_CONTENT_LENGTH);
        }

        if (title != null && title.length > MAX_NOTE_TITLE_LENGTH) {
            throw new GLib.IOError.INVALID_ARGUMENT ("Title exceeds maximum length of %d characters.", MAX_NOTE_TITLE_LENGTH);
        }

        var data = new NoteData ();
        if (title != null && title.strip () != "") {
            data.title = title;
        }
        if (content != null) {
            data.content = content;
        }
        if (theme_name != null && theme_name.strip () != "") {
            data.theme = Themes.from_string (theme_name, DEFAULT_THEME);
        }

        create_note (data);
        immediately_save ();
        return data;
    }

    /**
    * Update an existing note's properties, enforcing length guardrails and triggering UI update
    */
    public NoteData update_note_by_id (string id, string? title, string? content, string? theme_name) throws GLib.Error {
        var win = get_window_by_id (id);
        if (win == null) {
            throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
        }

        if (content != null && content.length > MAX_NOTE_CONTENT_LENGTH) {
            throw new GLib.IOError.INVALID_ARGUMENT ("Content exceeds maximum length of %d characters.", MAX_NOTE_CONTENT_LENGTH);
        }

        if (title != null && title.length > MAX_NOTE_TITLE_LENGTH) {
            throw new GLib.IOError.INVALID_ARGUMENT ("Title exceeds maximum length of %d characters.", MAX_NOTE_TITLE_LENGTH);
        }

        if (title != null) {
            win.update_title (title);
        }
        if (content != null) {
            win.update_content (content);
        }
        if (theme_name != null && theme_name.strip () != "") {
            win.update_theme (Themes.from_string (theme_name, win.popover.color));
        }

        immediately_save ();
        return win.packaged ();
    }

    /**
    * Delete an active note by UUID
    */
    public bool delete_note_by_id (string id) {
        var win = get_window_by_id (id);
        if (win == null) {
            return false;
        }
        delete_note (win);
        return true;
    }

    /**
    * Search all open notes by query string (case-insensitive in title and content)
    */
    public string search_notes_json_string (string query) {
        ensure_initialized ();
        var array = new Json.Array ();
        var normalized_query = query.strip ().down ();
        int count = 0;

        foreach (var note in open_notes) {
            var data = note.packaged ();
            if (data.title.down ().contains (normalized_query) || data.content.down ().contains (normalized_query)) {
                array.add_object_element (data.to_json ());
                count++;
                if (count >= MAX_SEARCH_RESULTS) {
                    break;
                }
            }
        }

        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        var gen = new Json.Generator ();
        gen.set_root (node);
        return gen.to_data (null);
    }
}
