/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * Coordinates focus-aware desktop chrome visibility.
     * Hides the action bar when notes are unfocused, reveals immediately upon focus,
     * and debounces hover reveals to prevent cursor-crossing flicker.
     */
    public class ChromeController : Object {

        public const uint HOVER_REVEAL_DELAY_MS = 250;

        private weak Gtk.Window? window;
        private weak Gtk.ActionBar? actionbar;
        private weak Gtk.Widget? root_widget;

        private Gtk.EventControllerMotion? motion_controller;
        private uint hover_timeout_id = 0;
        private bool _is_hovered = false;
        private bool _popover_active = false;

        private bool _autohide = true;
        public bool autohide {
            get { return _autohide; }
            set {
                _autohide = value;
                update_visibility ();
            }
        }

        public bool is_chrome_revealed {
            get {
                return actionbar != null ? actionbar.revealed : false;
            }
        }

        public ChromeController (Gtk.Window window, Gtk.ActionBar actionbar, Gtk.Widget root_widget) {
            this.window = window;
            this.actionbar = actionbar;
            this.root_widget = root_widget;

            motion_controller = new Gtk.EventControllerMotion ();
            motion_controller.enter.connect (on_mouse_enter);
            motion_controller.leave.connect (on_mouse_leave);
            root_widget.add_controller (motion_controller);

            window.notify["is-active"].connect (on_focus_changed);

            init_settings ();
            update_visibility ();
        }

        private void init_settings () {
            if (GLib.SettingsSchemaSource.get_default () != null) {
                var schema_source = GLib.SettingsSchemaSource.get_default ();
                if (schema_source != null && schema_source.lookup (APP_ID, true) != null) {
                    var settings = new GLib.Settings (APP_ID);
                    settings.bind (KEY_HIDEBAR, this, "autohide", SettingsBindFlags.INVERT_BOOLEAN);
                }
            }
        }

        private void on_focus_changed () {
            cancel_hover_timer ();
            update_visibility ();
        }

        private void on_mouse_enter (double x, double y) {
            _is_hovered = true;
            if (window == null || window.is_active || !_autohide || _popover_active) {
                return;
            }

            // Start debounce timer to avoid flickering during cursor sweeps
            cancel_hover_timer ();
            hover_timeout_id = GLib.Timeout.add (HOVER_REVEAL_DELAY_MS, on_hover_timer_fired);
        }

        private bool on_hover_timer_fired () {
            hover_timeout_id = 0;
            if (_is_hovered) {
                set_actionbar_revealed (true);
            }
            return GLib.Source.REMOVE;
        }

        private void on_mouse_leave () {
            _is_hovered = false;
            cancel_hover_timer ();

            if (window != null && !window.is_active && !_popover_active && _autohide) {
                set_actionbar_revealed (false);
            }
        }

        public void set_popover_active (bool active) {
            _popover_active = active;
            update_visibility ();
        }

        public void update_visibility () {
            if (window == null || actionbar == null) {
                return;
            }

            if (!_autohide || window.is_active || _popover_active) {
                set_actionbar_revealed (true);
            } else if (_is_hovered && hover_timeout_id == 0) {
                set_actionbar_revealed (true);
            } else {
                set_actionbar_revealed (false);
            }
        }

        private void set_actionbar_revealed (bool revealed) {
            if (actionbar != null && actionbar.revealed != revealed) {
                actionbar.revealed = revealed;
            }
        }

        private void cancel_hover_timer () {
            if (hover_timeout_id != 0) {
                GLib.Source.remove (hover_timeout_id);
                hover_timeout_id = 0;
            }
        }

        public override void dispose () {
            cancel_hover_timer ();
            base.dispose ();
        }

        ~ChromeController () {
            cancel_hover_timer ();
        }
    }
}
