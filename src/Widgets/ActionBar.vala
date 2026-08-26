/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

/**
 * Single-child custom ActionBar container.
 * Everything is kept there but most widgets are public
 */
public class Jots.ActionBar : Jots.Bin {

    public Gtk.ActionBar actionbar;
    public Gtk.Button list_button;
    public Gtk.MenuButton emoji_button;
    public Gtk.EmojiChooser emojichooser_popover;
    public Gtk.MenuButton menu_button;
    public Gtk.WindowHandle handle;
    public Jots.Popover popover;

    const int ICON_SIZE = 32;

    construct {

        /* **** LEFT **** */
        var new_item = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_NEW,
            icon_name = "list-add-symbolic",
            width_request = ICON_SIZE,
            height_request = ICON_SIZE,
            tooltip_markup = Jots.Util.markup_accel_tooltip (
                _("New sticky note"),
                "Ctrl+N"
            ),
            has_frame = false
        };
        new_item.add_css_class (STYLE_THEMEDBUTTON);

        var delete_item = new Gtk.Button () {
            action_name = StickyNoteWindow.ACTION_PREFIX + StickyNoteWindow.ACTION_DELETE,
            icon_name = "user-trash-symbolic",
            width_request = ICON_SIZE,
            height_request = ICON_SIZE,
            tooltip_markup = Jots.Util.markup_accel_tooltip (
                _("Delete sticky note"),
                "Ctrl+W"
            ),
            has_frame = false
        };
        delete_item.add_css_class (STYLE_THEMEDBUTTON);

        /* **** RIGHT **** */
        list_button = new Gtk.Button () {
            action_name = TextView.ACTION_PREFIX + TextView.ACTION_TOGGLE_LIST,
            icon_name = "view-list-symbolic",
            width_request = ICON_SIZE,
            height_request = ICON_SIZE,
            tooltip_markup = Jots.Util.markup_accel_tooltip (
                _("Toggle list"),
                "Shift+F12"
            ),
            has_frame = false
        };
        list_button.add_css_class (STYLE_THEMEDBUTTON);

        emojichooser_popover = new Gtk.EmojiChooser ();
        emoji_button = new Gtk.MenuButton () {
            popover = emojichooser_popover,
            icon_name = "face-smile-symbolic",
            width_request = ICON_SIZE,
            height_request = ICON_SIZE,
            tooltip_markup = Jots.Util.markup_accel_tooltip (
                _("Insert emoji"),
                "Ctrl+."
            ),
            has_frame = false
        };
        emoji_button.add_css_class (STYLE_THEMEDBUTTON);

        popover = new Jots.Popover ();
        menu_button = new Gtk.MenuButton () {
            popover = popover,
            icon_name = "open-menu-symbolic",
            width_request = ICON_SIZE,
            height_request = ICON_SIZE,
            tooltip_markup = Jots.Util.markup_accel_tooltip (
                _("Preferences for this sticky note"),
                "Ctrl+G"
            ),
            has_frame = false,
            direction = Gtk.ArrowType.UP
        };
        menu_button.add_css_class (STYLE_THEMEDBUTTON);

        /* **** Widget **** */
        actionbar = new Gtk.ActionBar () {
            hexpand = true
        };
        actionbar.revealed = false;
        actionbar.pack_start (new_item);
        actionbar.pack_start (delete_item);
        actionbar.pack_end (menu_button);
        actionbar.pack_end (emoji_button);
        actionbar.pack_end (list_button);

        handle = new Gtk.WindowHandle () {
            child = actionbar
        };

        child = handle;

        // Hide the list button if user has specified no list item symbol
        on_prefix_changed ();
        Application.settings.changed[KEY_LIST].connect (on_prefix_changed);
    }

    /**
    * Allow control of when to respect the hide-bar setting
    * StickyNoteWindow will decide itself whether to show immediately or not
    */
    public void reveal_bind () {
        Application.settings.bind (KEY_HIDEBAR,
            actionbar, "revealed",
            SettingsBindFlags.INVERT_BOOLEAN);
    }

    /**
    * If user leaves list prefix blank, then they dont need the button.
    */
    private void on_prefix_changed () {
        var is_disabled = Application.settings.get_enum (KEY_LIST) == ListPrefix.DISABLED;
        list_button.visible = !is_disabled;
    }

    ~ActionBar () {
        debug ("Destroyed");
    }
}
