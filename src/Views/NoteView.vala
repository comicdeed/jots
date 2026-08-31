/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

 public class Jots.NoteView : Gtk.Box {
    public Gtk.HeaderBar headerbar;
    public Jots.EditableLabel editablelabel;
    public Jots.TextView textview;
    public Jots.ActionBar actionbar;
    public Jots.Popover popover;

    public Gtk.MenuButton emoji_button;
    public Gtk.EmojiChooser emojichooser_popover;
    public Gtk.MenuButton menu_button;

    public Gtk.ScrolledWindow scrolled;

    public string title {
        owned get { return editablelabel.text;}
        set { editablelabel.text = value;}
    }

    public string content {
        owned get { return textview.text;}
        set { textview.text = value;}
    }

    public bool monospace {
        get { return textview.monospace;}
        set { mono_set (value);}
    }

    public Themes color {
        get { return popover.color;}
        set { popover.color = value;}
    }

    public signal void changed ();

    public SimpleActionGroup actions { get; construct; }
    public const string ACTION_PREFIX = "noteview.";
    public const string ACTION_FOCUS_TITLE = "action_focus_title";
    public const string ACTION_SHOW_EMOJI = "action_show_emoji";
    public const string ACTION_SHOW_MENU = "action_show_menu";
    public const string ACTION_TOGGLE_MONO = "action_toggle_mono";

    public static Gee.MultiMap<string, string> action_accelerators;

    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { ACTION_FOCUS_TITLE, action_focus_title},
        { ACTION_SHOW_EMOJI, action_show_emoji},
        { ACTION_SHOW_MENU, action_show_menu},
        { ACTION_TOGGLE_MONO, action_toggle_mono},
    };

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);

        // Translation view
        unowned var app = ((Gtk.Application) GLib.Application.get_default ());
        app.set_accels_for_action (ACTION_PREFIX + ACTION_FOCUS_TITLE, {"<Control>L"});
        app.set_accels_for_action (ACTION_PREFIX + ACTION_SHOW_EMOJI, {"<Control>period"});
        app.set_accels_for_action (ACTION_PREFIX + ACTION_SHOW_MENU, {"<Control>G", "<Control>O"});
        app.set_accels_for_action (ACTION_PREFIX + ACTION_TOGGLE_MONO, {"<Control>m"});




        orientation = VERTICAL;
        spacing = 0;

        headerbar = new Gtk.HeaderBar () {
            show_title_buttons = false
        };
        headerbar.add_css_class ("flat");
        headerbar.add_css_class ("headertitle");

        // Defime the label you can edit. Which is editable.
        editablelabel = new Jots.EditableLabel ();
        headerbar.set_title_widget (editablelabel);

        textview = new Jots.TextView ();
        scrolled = new Gtk.ScrolledWindow () {
            child = textview,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        actionbar = new Jots.ActionBar ();

        emoji_button = actionbar.emoji_button;
        emojichooser_popover = actionbar.emojichooser_popover;

        menu_button = actionbar.menu_button;
        var pop = menu_button.popover as Jots.Popover;
        if (pop != null) {
            popover = pop;
        }

        append (headerbar);
        append (scrolled);
        append (actionbar);


        /***************************************************/
        /*              CONNECTS AND BINDS                 */
        /***************************************************/

        emojichooser_popover.emoji_picked.connect (on_emoji_picked);
    }

    private void on_emoji_picked (string emoji) {
        debug ("Emote picked!");
        textview.buffer.insert_at_cursor (emoji, -1);
        set_focus_child (textview);
    }

    private void mono_set (bool if_mono) {
        editablelabel.monospace = if_mono;
        textview.monospace = if_mono;
        popover.monospace = if_mono;
        NoteData.latest_mono = if_mono;
    }

    private void action_focus_title () {editablelabel.editing = true;}
    private void action_show_emoji () {emoji_button.activate ();}
    private void action_show_menu () {menu_button.activate ();}
    private void action_toggle_mono () {monospace = !monospace;}

    ~NoteView () {
        debug ("Destroyed");
    }
}
