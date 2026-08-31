/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */


/**
* Represents a Sticky Note, with its own settings and content
* There is a View, which contains the text
* There is a Popover, which manages the per-window settings (Tail wagging the dog situation)
* Can be packaged into a noteData file for convenient storage
* Reports to the NoteManager for saving
*/
public class Jots.StickyNoteWindow : Gtk.ApplicationWindow {

    public Jots.NoteView view;
    public Popover popover;
    public TextView textview;

    public Jots.ChromeController chrome_controller;
    private Jots.ColorController color_controller;
    public Jots.ZoomController zoom_controller;
    private Jots.ScribblyController scribbly_controller;
    private Gtk.EventControllerScroll scroll_controller;
    private Gtk.GestureZoom gesturezoom_controller;

    public string note_id;

    public NoteData data {
        owned get {return packaged ();}
        set {load_data (value);}
    }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_DELETE = "action_delete";
    public const string ACTION_SEARCH = "action_search";

    public Jots.SearchPopover search_popover;

    public static Gee.MultiMap<string, string> action_accelerators;
    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { ACTION_DELETE, action_delete },
        { ACTION_SEARCH, action_show_search }
    };

    public StickyNoteWindow (Jots.Application app, NoteData data) {
        Intl.setlocale ();
        debug ("New StickyNoteWindow instance!");
        application = app;
        icon_name = APP_ID;
#if DEVEL
        title = _("Jots (Development)");
#else
        title = _("Jots");
#endif

        var actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group ("win", actions);
        app.set_accels_for_action (ACTION_PREFIX + ACTION_DELETE, {"<Control>W"});
        app.set_accels_for_action (ACTION_PREFIX + ACTION_SEARCH, {"<Control>f", "<Control><Shift>f"});

        color_controller = new Jots.ColorController (this);
        zoom_controller = new Jots.ZoomController (this);
        scribbly_controller = new Jots.ScribblyController (this);

        scroll_controller = new Gtk.EventControllerScroll (VERTICAL) {
            propagation_phase = Gtk.PropagationPhase.CAPTURE
        };

        gesturezoom_controller = new Gtk.GestureZoom ();

        ((Gtk.Widget)this).add_controller (scroll_controller);
        ((Gtk.Widget)this).add_controller (gesturezoom_controller);

        // The view has its own titlebar
        titlebar = new Gtk.Grid () {visible = false};

        view = new NoteView ();
        textview = view.textview;
        insert_action_group ("noteview", view.actions);
        insert_action_group ("textview", textview.actions);
        insert_action_group ("zoom_controller", zoom_controller.actions);

        // Have shortcuts keep working with the popover open.
        popover = view.popover;
        view.popover.scroll_controller.scroll.connect ((dx, dy) => zoom_controller.on_scroll (view.popover.scroll_controller, dx, dy));

        //zoom_controller.notify["zoom"].connect_after (textview.refresh_indentation);

        set_child (view);
        set_focus (view);
        load_data (data);

        search_popover = new Jots.SearchPopover (Application.note_manager);
        search_popover.set_parent (view.headerbar);

        chrome_controller = new Jots.ChromeController (this, view.actionbar.actionbar, view);

#if DEVEL
        add_css_class (STYLE_DEVEL);
#endif
        add_css_class (STYLE_ANIMATED);


        /***************************************************/
        /*              CONNECTS AND BINDS                 */
        /***************************************************/

        // Zoom via Ctrl + Scroll or Pinch gesture
        scroll_controller.scroll.connect ((dx, dy) => zoom_controller.on_scroll (scroll_controller, dx, dy));
        gesturezoom_controller.scale_changed.connect (zoom_controller.on_pinch);

        debug ("Built UI. Lets do connects and binds");

        // Save when title or text have changed
        view.editablelabel.changed.connect (on_editable_changed);
        view.textview.buffer.changed.connect (has_changed);
        popover.theme_changed.connect (color_controller.on_color_changed);
        popover.readonly_toggled.connect (on_popover_readonly_toggled);
        popover.always_visible_toggled.connect (on_popover_always_visible_toggled);

        view.menu_button.notify["active"].connect (on_menu_button_toggled);
        view.emoji_button.notify["active"].connect (on_emoji_button_toggled);
        popover.closed.connect (on_menu_popover_closed);
        search_popover.closed.connect (on_search_popover_closed);

        sync_dark_mode ();
    }

    /**
    * Simple handler for the EditableLabel
    */
    private void on_editable_changed () {
        if (view.title != null && view.title.strip () != "") {
#if DEVEL
            title = _("%s - Jots (Development)").printf (view.title);
#else
            title = _("%s - Jots").printf (view.title);
#endif
        } else {
#if DEVEL
            title = _("Jots (Development)");
#else
            title = _("Jots");
#endif
        }
        has_changed ();
    }

    public bool is_readonly {
        get { return _readonly; }
        set {
            _readonly = value;
            textview.editable = !value;
            view.editablelabel.sensitive = !value;
            view.emoji_button.sensitive = !value;
            popover.is_readonly = value;
            has_changed ();
        }
    }
    private bool _readonly = false;

    public bool always_visible {
        get { return _always_visible; }
        set {
            _always_visible = value;
            popover.is_always_visible = value;
            scribbly_controller.always_visible = value;
            has_changed ();
        }
    }
    private bool _always_visible = false;

    /**
    * Package the note into a NoteData and pass it back.
    * Used by NoteManager to pass all informations conveniently for storage
    */
    public NoteData packaged () {
        debug ("Packaging into a noteData…");

        int this_width ; int this_height;
        this.get_default_size (out this_width, out this_height);

        var data = new NoteData () {
            id = (note_id != null && note_id != "") ? note_id : GLib.Uuid.string_random (),
            title = view.title,
            theme = popover.color,
            content = view.content,
            monospace = popover.monospace,
            zoom = zoom_controller.zoom,
            width = this_width,
            height = this_height,
            readonly = this.is_readonly,
            always_visible = this.always_visible
        };

        return data;
    }

    /**
    * Propagate the content of a NoteData into the various UI elements. Used when creating a new window
    */
    private void load_data (NoteData data) {
        debug ("Loading noteData…");

        note_id = data.id;
        set_default_size (data.width, data.height);
        view.title = data.title;

        if (data.id == CHEATSHEET_NOTE_ID) {
            data.readonly = true;
            data.always_visible = true;
        }

        _readonly = data.readonly;
        textview.editable = !_readonly;
        view.editablelabel.sensitive = !_readonly;
        view.emoji_button.sensitive = !_readonly;
        popover.is_readonly = _readonly;

        _always_visible = data.always_visible;
        popover.is_always_visible = _always_visible;
        scribbly_controller.always_visible = _always_visible;

        if (data.id == CHEATSHEET_NOTE_ID) {
            popover.set_controls_locked (true);
        }

        if (view.title != null && view.title.strip () != "") {
#if DEVEL
            title = _("%s - Jots (Development)").printf (view.title);
#else
            title = _("%s - Jots").printf (view.title);
#endif
        } else {
#if DEVEL
            title = _("Jots (Development)");
#else
            title = _("Jots");
#endif
        }

        view.content = data.content;

        color_controller.theme = data.theme;
        zoom_controller.zoom = data.zoom;
        view.monospace = data.monospace;
    }

    public void update_title (string new_title) {
        view.title = new_title;
        if (new_title.strip () != "") {
#if DEVEL
            title = _("%s - Jots (Development)").printf (new_title);
#else
            title = _("%s - Jots").printf (new_title);
#endif
        } else {
#if DEVEL
            title = _("Jots (Development)");
#else
            title = _("Jots");
#endif
        }
        has_changed ();
    }

    public void update_content (string new_content) {
        view.content = new_content;
        has_changed ();
    }

    public void update_theme (Jots.Themes new_theme) {
        popover.color = new_theme;
        color_controller.theme = new_theme;
        has_changed ();
    }

    public void has_changed () {
        application.activate_action (Application.ACTION_SAVE, null);
    }

    private void action_delete () {
        Application.note_manager.delete_note (this);
    }

    public void sync_dark_mode () {
        if (Application.gtk_settings.gtk_application_prefer_dark_theme) {
            add_css_class ("dark");
        } else {
            remove_css_class ("dark");
        }
        queue_draw ();
    }

    private void action_show_search () {
        if (chrome_controller != null) {
            chrome_controller.set_popover_active (true);
        }
        search_popover.popup ();
        search_popover.focus_and_select ();
    }

    private void on_menu_button_toggled () {
        if (chrome_controller != null) {
            chrome_controller.set_popover_active (view.menu_button.active);
        }
    }

    private void on_emoji_button_toggled () {
        if (chrome_controller != null) {
            chrome_controller.set_popover_active (view.emoji_button.active);
        }
    }

    private void on_menu_popover_closed () {
        if (chrome_controller != null) {
            chrome_controller.set_popover_active (false);
        }
    }

    private void on_search_popover_closed () {
        if (chrome_controller != null) {
            chrome_controller.set_popover_active (false);
        }
    }

    private void on_popover_readonly_toggled (bool active) {
        if (note_id != CHEATSHEET_NOTE_ID) {
            this.is_readonly = active;
        }
    }

    private void on_popover_always_visible_toggled (bool active) {
        if (note_id != CHEATSHEET_NOTE_ID) {
            this.always_visible = active;
        }
    }

    public override void dispose () {
        if (search_popover != null) {
            search_popover.unparent ();
            search_popover = null;
        }

        if (chrome_controller != null) {
            chrome_controller.dispose ();
            chrome_controller = null;
        }

        base.dispose ();
    }

    ~StickyNoteWindow () {
        debug ("Destroying %s", view.title);
    }
}
