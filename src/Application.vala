/*
* Copyright (c) 2017-2024 Lains
* Copyright (c) 2025 Stella, Charlie, (teamcons on GitHub) and the Ellie_Commons community
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/


/*
Application creates a NoteManager, which is the OG thing that does the heavy lifting.
NoteManager retrieves a list of NoteData from the Stash
Then it untangles it and creates a list of windows it can keep track of.

When a note get deleted, the window signals to the manager to remove it from the list
When a new note is requested, the manager creates a new window and adds it
When saving is requested, the manager goes though the whole list requesting every window to package itself, then slams all onto disk.

The Preferences window is supposed to be a static window.

NoteData is a convenience object to pass around sticky notes
Stash deals with writing/loading from the disk
Themer spits the different themes upon startup
Utils spits all the random
Jason deals with all the hassle in between all saving/loading steps
Constants is because i am lazy
*/

public class Jots.Application : Gtk.Application {

    // Needed by all windows
    public static GLib.Settings settings;
    public static Gtk.Settings gtk_settings;

    public static Jots.NoteManager note_manager;
    public static Jots.FontController font_controller;
    public static Jots.PreferenceWindow? preferences;
    public static Jots.NoteService? note_service;
    public static Jots.GitSyncService? git_sync_service;
    private uint dbus_registration_id = 0;

    // Used for commandline option handling
    public static bool new_note = false;
    public static bool show_pref = false;

    public const string ACTION_PREFIX = "app.";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_TOGGLE_SCRIBBLY = "action_toggle_scribbly";
    public const string ACTION_TOGGLE_ACTIONBAR = "action_toggle_actionbar";
    public const string ACTION_SHOW_PREFERENCES = "action_show_preferences";

    public const string ACTION_NEW = "action_new";
    public const string ACTION_SAVE = "action_save";
    public const string ACTION_RESTORE_LAST = "action_restore_last";
    public const string ACTION_SHOW_CHEATSHEET = "action_show_cheatsheet";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { ACTION_QUIT, quit},
        { ACTION_TOGGLE_SCRIBBLY, action_toggle_scribbly},
        { ACTION_TOGGLE_ACTIONBAR, action_toggle_actionbar},
        { ACTION_SHOW_PREFERENCES, action_show_preferences},
        { ACTION_NEW, nm_new_note},
        { ACTION_SAVE, nm_save_all},
        { ACTION_RESTORE_LAST, nm_restore_last_deleted},
        { ACTION_SHOW_CHEATSHEET, action_show_cheatsheet}
    };

    public Application () {
        Object (flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                application_id: APP_ID);
    }

    /*************************************************/
    static construct {
        settings = new GLib.Settings (APP_ID);
    }

    /*************************************************/
    construct {
        // The localization thingamabob
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

#if DEVEL
        //GLib.Environment.set_variable ("LANGUAGE", "C", true);
        GLib.Environment.set_variable ("GTK_DEBUG", "interactive", true);
        //print (LOCALEDIR);
#endif
    }

    /*************************************************/
    protected override bool dbus_register (DBusConnection connection, string object_path) throws GLib.Error {
        if (!base.dbus_register (connection, object_path)) {
            return false;
        }

        if (note_manager == null) {
            note_manager = new Jots.NoteManager (this);
        }

        note_service = new Jots.NoteService (note_manager);

        try {
            dbus_registration_id = connection.register_object (object_path + "/Notes", note_service);
            connection.register_object (object_path, note_service);
        } catch (IOError e) {
            warning ("Could not register NoteService on D-Bus: %s", e.message);
        }

        return true;
    }

    protected override void dbus_unregister (DBusConnection connection, string object_path) {
        if (dbus_registration_id > 0) {
            connection.unregister_object (dbus_registration_id);
            dbus_registration_id = 0;
        }
        base.dbus_unregister (connection, object_path);
    }

    /*************************************************/
    public override void startup () {
        debug ("Jots Startup…");
        base.startup ();
        Gtk.init ();

        Gtk.Window.set_default_icon_name (APP_ID);

        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>Q"});
        set_accels_for_action (ACTION_PREFIX + ACTION_SHOW_PREFERENCES, {"<Control>P"});
        set_accels_for_action (ACTION_PREFIX + ACTION_TOGGLE_ACTIONBAR, {"<Control>T"});
        set_accels_for_action (ACTION_PREFIX + ACTION_TOGGLE_SCRIBBLY, {"<Control>H"});

        set_accels_for_action (ACTION_PREFIX + ACTION_NEW, {"<Control>N"});
        set_accels_for_action (ACTION_PREFIX + ACTION_SAVE, {"<Control>S"});
        set_accels_for_action (ACTION_PREFIX + ACTION_RESTORE_LAST, {"<Control>R"});
        set_accels_for_action (ACTION_PREFIX + ACTION_SHOW_CHEATSHEET, {"F1"});

        if (note_manager == null) {
            note_manager = new Jots.NoteManager (this);
        }
        git_sync_service = new Jots.GitSyncService (note_manager.storage, settings);
        git_sync_service.initialize ();
        font_controller = new Jots.FontController ();

#if LIBPORTAL
        // Sync the autostart toggle to actual filesystem state.
        // GSettings tracks user intent; the .desktop file on disk is ground truth.
        sync_autostart_state ();
#endif
        var action_restore = lookup_action (Application.ACTION_RESTORE_LAST) as SimpleAction;
        if (action_restore != null) {
            action_restore.set_enabled (false);
        }

        // Set default icon theme
        gtk_settings = Gtk.Settings.get_default ();
        if (GLib.Environment.get_variable ("GTK_THEME") != null) {
            gtk_settings.gtk_theme_name = GLib.Environment.get_variable ("GTK_THEME");
        }

        init_color_scheme_sync ();

        /* Quit if all sticky notes are closed and preferences arent shown */
        window_removed.connect (check_if_quit);

        // build all the stylesheets
        var app_provider = new Gtk.CssProvider ();
        app_provider.load_from_resource (APP_PATH + "/Application.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            app_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
        );

        var theme_provider = new Gtk.CssProvider ();
        theme_provider.load_from_resource (APP_PATH + "/Themes.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            theme_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 2
        );

        // Register bundled monochrome actionbar icons from GResource
        var display = Gdk.Display.get_default ();
        if (display != null) {
            Gtk.IconTheme.get_for_display (display).add_resource_path (APP_PATH + "/icons");
        }
    }

    // Clicked: Either show all windows, or rebuild from storage
    protected override void activate () {
        debug ("Jots, activate!");

        // Test Lang
        //GLib.Environment.set_variable ("LANGUAGE", "pt_br", true);

        /* Either we show all sticky notes, or we load everything lol */
        if (note_manager.open_notes.size > 0) {
            foreach (var window in note_manager.open_notes) {
                if (window.visible) {window.present ();}
            }
        } else {
            note_manager.init ();
        }

        if (new_note) {note_manager.create_note (); new_note = false;}
        if (show_pref) {action_show_preferences (); show_pref = false;}
    }

    public static int main (string[] args) {
        GLib.Environment.set_prgname (APP_ID);
        GLib.Environment.set_application_name ("Jots");
        return new Application ().run (args);
    }

    private void action_show_preferences () {
        debug ("Showing preferences!");

        if (Application.preferences == null) {
            Application.preferences = new Jots.PreferenceWindow (this);
            Application.preferences.close_request.connect (() => {
                Idle.add (() => {
                    Application.preferences = null;
                    return Source.REMOVE;
                });
                return false;
            });
        }

        preferences.present ();
    }

    private void action_toggle_scribbly () {
        debug ("Toggling scribbly");
        var current = Application.settings.get_boolean (KEY_SCRIBBLY);
        settings.set_boolean (KEY_SCRIBBLY, !current);
    }

    private void action_toggle_actionbar () {
        debug ("Toggling actionbar");
        var current = Application.settings.get_boolean (KEY_HIDEBAR);
        settings.set_boolean (KEY_HIDEBAR, !current);
    }

    private void nm_new_note () {
        note_manager.new_note ();
    }

    private void nm_save_all () {
        note_manager.save_all ();
    }

    private void nm_restore_last_deleted () {
        note_manager.restore_last_deleted ();
    }

    private void action_show_cheatsheet () {
        note_manager.show_cheatsheet ();
    }

    // checked upon window closing to make sure we do not linger in the background
    public void check_if_quit () {
        debug ("Windows open: %s".printf (get_windows ().length ().to_string ()));

        if (get_windows ().length () == 0) {
            debug ("No sticky note open, quitting");
            quit ();
        }
    }

    public override int command_line (ApplicationCommandLine command_line) {
        debug ("Parsing commandline arguments");

        OptionEntry[] cmd_option_entries = {
            {"new-note", 'n', OptionFlags.NONE, OptionArg.NONE, ref new_note, _("Create a new note"), null},
            {"preferences", 'p', OptionFlags.NONE, OptionArg.NONE, ref show_pref, _("Show preferences"), null}
        };

        // We have to make an extra copy of the array, since .parse assumes
        // that it can remove strings from the array without freeing them.
        string[] args = command_line.get_arguments ();
        string[] _args = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }

        try {
            var ctx = new OptionContext ();
            ctx.set_help_enabled (true);
            ctx.add_main_entries (cmd_option_entries, null);
            unowned string[] tmp = _args;
            ctx.parse (ref tmp);

        } catch (OptionError e) {
            command_line.print ("error: %s\n", e.message);
            return 0;
        }

        activate ();
        return 0;
    }

    public override void shutdown () {
        if (git_sync_service != null) {
            git_sync_service.shutdown ();
        }

        base.shutdown ();
    }

#if LIBPORTAL
    private void sync_autostart_state () {
        var actual = Jots.Autostart.is_active ();
        var stored = settings.get_boolean (KEY_AUTOSTART);
        if (actual != stored) {
            debug ("Autostart state desync detected: filesystem=%s gsettings=%s — correcting",
                actual.to_string (), stored.to_string ());
            settings.set_boolean (KEY_AUTOSTART, actual);
        }
    }
#endif

    private uint portal_signal_id = 0;

    private void init_color_scheme_sync () {
        // 1. Initial detection via XDG Portal
        sync_system_dark_mode ();

        // 2. Subscribe to FreeDesktop XDG Portal SettingChanged signal (universal across all DEs & Flatpaks)
        try {
            var conn = GLib.Bus.get_sync (GLib.BusType.SESSION, null);
            portal_signal_id = conn.signal_subscribe (
                null,
                "org.freedesktop.portal.Settings",
                "SettingChanged",
                null,
                null,
                GLib.DBusSignalFlags.NONE,
                on_portal_setting_changed
            );
        } catch (GLib.Error e) {
            debug ("Could not subscribe to XDG Portal SettingChanged: %s", e.message);
        }

        // 3. Listen to standard GTK theme property changes
        gtk_settings.notify["gtk-theme-name"].connect (() => {
            sync_system_dark_mode ();
        });
        gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
            update_all_windows_dark_mode ();
        });

        settings.changed[KEY_DARK_NOTE_STYLE].connect (() => {
            update_all_windows_dark_mode ();
        });
    }

    private void on_portal_setting_changed (GLib.DBusConnection connection,
                                            string? sender_name,
                                            string object_path,
                                            string interface_name,
                                            string signal_name,
                                            GLib.Variant parameters) {
        if (parameters.n_children () >= 3) {
            string ns = parameters.get_child_value (0).get_string ();
            string key = parameters.get_child_value (1).get_string ();
            if (ns == "org.freedesktop.appearance" && key == "color-scheme") {
                GLib.Variant val = parameters.get_child_value (2);
                while (val.is_of_type (GLib.VariantType.VARIANT)) {
                    val = val.get_variant ();
                }
                uint32 scheme = val.get_uint32 ();
                debug ("XDG Portal SettingChanged received color-scheme: %u", scheme);
                if (scheme == 1) {
                    gtk_settings.gtk_application_prefer_dark_theme = true;
                } else {
                    // FreeDesktop Portal: 2 = prefer-light, 0 = default / no-preference (light)
                    gtk_settings.gtk_application_prefer_dark_theme = false;
                }
                update_all_windows_dark_mode ();
            }
        }
    }

    public void sync_system_dark_mode () {
        if (GLib.Environment.get_variable ("FORCE_DARK") == "1") {
            gtk_settings.gtk_application_prefer_dark_theme = true;
            update_all_windows_dark_mode ();
            return;
        }
        if (GLib.Environment.get_variable ("FORCE_LIGHT") == "1") {
            gtk_settings.gtk_application_prefer_dark_theme = false;
            update_all_windows_dark_mode ();
            return;
        }

        bool is_dark = false;
        bool portal_resolved = false;

        // Primary: Query standard FreeDesktop XDG Portal
        try {
            var conn = GLib.Bus.get_sync (GLib.BusType.SESSION, null);
            var result = conn.call_sync (
                "org.freedesktop.portal.Desktop",
                "/org/freedesktop/portal/desktop",
                "org.freedesktop.portal.Settings",
                "Read",
                new GLib.Variant ("(ss)", "org.freedesktop.appearance", "color-scheme"),
                new GLib.VariantType ("(v)"),
                GLib.DBusCallFlags.NONE,
                1000,
                null
            );
            if (result != null) {
                GLib.Variant val = result.get_child_value (0);
                while (val.is_of_type (GLib.VariantType.VARIANT)) {
                    val = val.get_variant ();
                }
                uint32 scheme = val.get_uint32 ();
                debug ("XDG Portal Read color-scheme: %u", scheme);
                if (scheme == 1) { // 1 = prefer-dark
                    is_dark = true;
                } else { // 2 = prefer-light, 0 = default / no-preference
                    is_dark = false;
                }
                portal_resolved = true;
            }
        } catch (GLib.Error e) {
            debug ("XDG Portal Settings.Read fallback: %s", e.message);
        }

        if (!portal_resolved) {
            if (gtk_settings.gtk_theme_name != null && gtk_settings.gtk_theme_name.down ().contains ("dark")) {
                is_dark = true;
            } else {
                is_dark = false;
            }
        }

        gtk_settings.gtk_application_prefer_dark_theme = is_dark;
        update_all_windows_dark_mode ();
    }

    public void update_all_windows_dark_mode () {
        if (note_manager != null) {
            foreach (var note in note_manager.open_notes) {
                note.sync_dark_mode ();
            }
        }
        foreach (var win in get_windows ()) {
            if (win is StickyNoteWindow) {
                ((StickyNoteWindow)win).sync_dark_mode ();
            }
        }
    }
}
