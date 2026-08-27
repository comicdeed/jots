/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

 // vala-lint=skip-file

/*************************************************/
/**
* An object used to package all data conveniently as needed.
*/
public class Jots.NoteData {

    // Will determine properties (or lack thereof) for any new note
    public static Jots.Themes latest_theme = DEFAULT_THEME;
    public static int latest_zoom = DEFAULT_ZOOM;
    public static bool latest_mono = DEFAULT_MONO;

    public string id;
    public string title;
    public Jots.Themes theme;
    public string content;
    public bool monospace;
    public int zoom;
    public int width;
    public int height;
    public bool readonly;
    public bool always_visible;

    // The standard constructor only does random
    public NoteData () {
        id = GLib.Uuid.string_random ();
        title = Jots.Utils.random_title ();
        theme = Jots.Themes.random_theme (latest_theme);
        content = "";
        monospace = latest_mono;
        zoom = latest_zoom;
        width = DEFAULT_WIDTH;
        height = DEFAULT_HEIGHT;
        readonly = false;
        always_visible = false;
    }    

    /*************************************************/
    /**
    * Parse a node to create an associated NoteData object
    */
    public NoteData.from_json (Json.Object node) {
        id          = node.get_string_member_with_default ("id", GLib.Uuid.string_random ());
        // Translators: "Forgot title!" is optional. It never happened for me when testing, and may appear only if users tampered with the savefile
        title       = node.get_string_member_with_default ("title", (_("Forgot title!")));
        theme       = (Jots.Themes)node.get_int_member_with_default ("color", Jots.Themes.random_theme ());
        content     = node.get_string_member_with_default ("content", "");
        monospace   = node.get_boolean_member_with_default ("monospace", DEFAULT_MONO);
        zoom        = (int)node.get_int_member_with_default ("zoom", DEFAULT_ZOOM);

        // Make sure the values are nothing crazy
        if (zoom < ZOOM_MIN)        { zoom = ZOOM_MIN;}
        else if (zoom > ZOOM_MAX)   { zoom = ZOOM_MAX;}

        width          = (int)node.get_int_member_with_default ("width", DEFAULT_WIDTH);
        height         = (int)node.get_int_member_with_default ("height", DEFAULT_HEIGHT);
        readonly       = node.get_boolean_member_with_default ("readonly", false);
        always_visible = node.get_boolean_member_with_default ("always_visible", false);
    }

    /*************************************************/
    /**
    * Used for storing NoteData inside disk storage
    */
    public Json.Object to_json () {
        var builder = new Json.Builder ();

        // Lets fkin gooo
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id);
        builder.set_member_name ("title");
        builder.add_string_value (title);
        builder.set_member_name ("color");
        builder.add_int_value (theme);
        builder.set_member_name ("content");
        builder.add_string_value (content);
        builder.set_member_name ("monospace");
        builder.add_boolean_value (monospace);
        builder.set_member_name ("zoom");
        builder.add_int_value (zoom);
        builder.set_member_name ("width");
        builder.add_int_value (width);
        builder.set_member_name ("height");
        builder.add_int_value (height);
        builder.set_member_name ("readonly");
        builder.add_boolean_value (readonly);
        builder.set_member_name ("always_visible");
        builder.add_boolean_value (always_visible);
        builder.end_object ();

        return builder.get_root ().get_object ();
    }

    /*************************************************/
    /**
    * Parse Markdown text with YAML front matter into a NoteData object
    */
    public NoteData.from_markdown (string md_content, string? fallback_id = null, string? fallback_title = null) {
        var parsed = Jots.MarkdownSerializer.deserialize (md_content, fallback_id, fallback_title);
        this.id = parsed.id;
        this.title = parsed.title;
        this.theme = parsed.theme;
        this.content = parsed.content;
        this.monospace = parsed.monospace;
        this.zoom = parsed.zoom;
        this.width = parsed.width;
        this.height = parsed.height;
        this.readonly = parsed.readonly;
        this.always_visible = parsed.always_visible;
    }

    /*************************************************/
    /**
    * Returns the Markdown string representation with YAML front matter
    */
    public string to_markdown () {
        return Jots.MarkdownSerializer.serialize (this);
    }

    /*************************************************/
    /**
    * Returns the JSON string representation of the note
    */
    public string to_json_string () {
        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (to_json ());
        var gen = new Json.Generator ();
        gen.set_root (node);
        return gen.to_data (null);
    }
}
