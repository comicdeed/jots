/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */


/* CONTENT

Preferences is boring
Everything is in a Handle so user can move the window from anywhere
It is a box, with inside of it a box and an actionbar

the innerbox has widgets for settings.
the actionbar has a donate me and a set back to defaults just like elementaryOS

*/
public class Jots.PreferenceWindow : Gtk.Window {

    const int DEFAULT_PREF_HEIGHT = 420;
    const int DEFAULT_PREF_WIDTH = 560;

    public PreferenceWindow (Jots.Application app) {
        debug ("Creating preference window");
        Intl.setlocale ();

        application = app;
        icon_name = APP_ID;

#if DEVEL
        add_css_class (STYLE_DEVEL);
#endif

        /********************************************/
        /*              HEADERBAR BS                */
        /********************************************/

#if DEVEL
        title = _("Preferences - Jots (Development)");
#else
        title = _("Preferences - Jots");
#endif

        var title_label = new Gtk.Label (_("<b>Preferences for your Jots</b>")) {
            use_markup = true
        };

        var prefview = new Jots.PreferencesView ();

        var header_title = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        header_title.append (title_label);
        header_title.append (prefview.page_switcher);

        var headerbar = new Gtk.HeaderBar () {
            // TRANSLATORS: Feel free to improvise. The goal is a playful wording to convey the idea of app-wide settings for Jots
            title_widget = header_title,
            show_title_buttons = false
        };
        headerbar.add_css_class ("flat");

        set_titlebar (headerbar);
        set_size_request (DEFAULT_PREF_WIDTH, DEFAULT_PREF_HEIGHT);
        set_default_size (DEFAULT_PREF_WIDTH, DEFAULT_PREF_HEIGHT);
        resizable = false;

        // Make the whole window grabbable
        var handle = new Gtk.WindowHandle () {
            child = prefview
        };

        this.child = handle;

        set_focus (prefview.close_button);
    }
}
