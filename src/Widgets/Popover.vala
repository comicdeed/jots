/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

/**
* The popover menu to tweak individual notes
* Contains a setting for color, one for monospace font, one for zoom
*/
public class Jots.Popover : Gtk.Popover {

    public Gtk.EventControllerKey keypress_controller;
    public Gtk.EventControllerScroll scroll_controller;

    private Jots.ColorBox color_box;
    private Jots.MonospaceBox monospace_box;
    private Jots.ZoomBox font_size_box;
    private Jots.ToggleRow readonly_row;
    private Jots.ToggleRow always_visible_row;

    public Themes color {
        get {return color_box.color;}
        set {color_box.color = value;}
    }

    public bool monospace {
        get {return monospace_box.monospace;}
        set {on_monospace_changed (value);}
    }

    public int zoom { set {font_size_box.zoom = value;}}

    public bool is_readonly {
        get { return readonly_row.active; }
        set { readonly_row.active = value; }
    }

    public bool is_always_visible {
        get { return always_visible_row.active; }
        set { always_visible_row.active = value; }
    }

    public signal void theme_changed (Jots.Themes selected);
    public signal void readonly_toggled (bool is_readonly);
    public signal void always_visible_toggled (bool is_always_visible);

    public void set_controls_locked (bool locked) {
        readonly_row.row_sensitive = !locked;
        always_visible_row.row_sensitive = !locked;
    }

    public Popover () {
        Object (
            position: Gtk.PositionType.TOP,
            halign: Gtk.Align.END
        );
    }

    static construct {
        add_binding_action (Gdk.Key.plus, Gdk.ModifierType.CONTROL_MASK, ZoomController.ACTION_PREFIX + ZoomController.ACTION_ZOOM_IN, null);
        add_binding_action (Gdk.Key.equal, Gdk.ModifierType.CONTROL_MASK, ZoomController.ACTION_PREFIX + ZoomController.ACTION_ZOOM_DEFAULT, null);
        add_binding_action (48, Gdk.ModifierType.CONTROL_MASK, ZoomController.ACTION_PREFIX + ZoomController.ACTION_ZOOM_DEFAULT, null);
        add_binding_action (Gdk.Key.minus, Gdk.ModifierType.CONTROL_MASK, ZoomController.ACTION_PREFIX + ZoomController.ACTION_ZOOM_OUT, null);

        add_binding_action (Gdk.Key.n, Gdk.ModifierType.CONTROL_MASK, Application.ACTION_PREFIX + Application.ACTION_NEW, null);
        add_binding_action (Gdk.Key.w, Gdk.ModifierType.CONTROL_MASK, StickyNoteWindow.ACTION_PREFIX + StickyNoteWindow.ACTION_DELETE, null);
        add_binding_action (Gdk.Key.l, Gdk.ModifierType.CONTROL_MASK, NoteView.ACTION_PREFIX + NoteView.ACTION_FOCUS_TITLE, null);
        add_binding_action (Gdk.Key.g, Gdk.ModifierType.CONTROL_MASK, NoteView.ACTION_PREFIX + NoteView.ACTION_SHOW_MENU, null);
        add_binding_action (Gdk.Key.o, Gdk.ModifierType.CONTROL_MASK, NoteView.ACTION_PREFIX + NoteView.ACTION_SHOW_MENU, null);
        add_binding_action (Gdk.Key.m, Gdk.ModifierType.CONTROL_MASK, NoteView.ACTION_PREFIX + NoteView.ACTION_TOGGLE_MONO, null);
        add_binding_action (Gdk.Key.f, Gdk.ModifierType.CONTROL_MASK, StickyNoteWindow.ACTION_PREFIX + StickyNoteWindow.ACTION_SEARCH, null);
        add_binding_action (Gdk.Key.F, Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, StickyNoteWindow.ACTION_PREFIX + StickyNoteWindow.ACTION_SEARCH, null);
        add_binding_action (Gdk.Key.F1, 0, Application.ACTION_PREFIX + Application.ACTION_SHOW_CHEATSHEET, null);

        add_binding_action (Gdk.Key.F12, Gdk.ModifierType.SHIFT_MASK, TextView.ACTION_PREFIX + TextView.ACTION_TOGGLE_LIST, null);
   }

    construct {
        var view = new Gtk.Box (VERTICAL, SPACING_DOUBLE) {
            margin_top = SPACING_DOUBLE,
            margin_bottom = SPACING_DOUBLE
        };

        color_box = new Jots.ColorBox ();
        monospace_box = new Jots.MonospaceBox ();
        font_size_box = new Jots.ZoomBox ();
        readonly_row = new Jots.ToggleRow (_("Lock Note (Read-Only)"), _("Prevent accidental edits or deletions"));
        always_visible_row = new Jots.ToggleRow (_("Always Visible"), _("Exempt from Privacy (Scribbly) obfuscation"));

        view.append (color_box);
        view.append (monospace_box);
        view.append (font_size_box);
        view.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        view.append (readonly_row);
        view.append (always_visible_row);

        readonly_row.toggled.connect (on_readonly_toggled);
        always_visible_row.toggled.connect (on_always_visible_toggled);

        child = view;

        // Allow scrolling shenanigans from popover
        keypress_controller = new Gtk.EventControllerKey ();
        scroll_controller = new Gtk.EventControllerScroll (VERTICAL) {
            propagation_phase = Gtk.PropagationPhase.CAPTURE
        };

        ((Gtk.Widget)this).add_controller (keypress_controller);
        ((Gtk.Widget)this).add_controller (scroll_controller);

        // Propagate settings changes to the higher level
        color_box.theme_changed.connect ((theme) => {theme_changed (theme);});
    }

    private void on_readonly_toggled (bool active) {
        readonly_toggled (active);
    }

    private void on_always_visible_toggled (bool active) {
        always_visible_toggled (active);
    }

    /**
    * Switches the .monospace class depending on the note setting
    */
    private void on_monospace_changed (bool monospace) {
        debug ("Updating monospace to %s".printf (monospace.to_string ()));
        monospace_box.monospace = monospace;
        Jots.NoteData.latest_mono = monospace;
    }

    ~Popover () {
        debug ("Destroyed");
        readonly_row.toggled.disconnect (on_readonly_toggled);
        always_visible_row.toggled.disconnect (on_always_visible_toggled);
    }
}
