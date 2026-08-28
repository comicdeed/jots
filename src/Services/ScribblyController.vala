/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * Responsible for applying RedactedScript font obfuscation to unfocused sticky note windows.
     */
    public class ScribblyController : Object {

        private const string STYLE_SCRIBBLED = "scribbled";
        private const string STYLE_UNFOCUSED = "is-unfocused";
        private weak Gtk.Window window;
        private GLib.Settings? settings;

        private bool _scribble;
        public bool scribble {
            get { return _scribble; }
            set {
                _scribble = value;
                update_scribble_state ();
            }
        }

        private bool _always_visible = false;
        public bool always_visible {
            get { return _always_visible; }
            set {
                _always_visible = value;
                update_scribble_state ();
            }
        }

        public ScribblyController (Gtk.Window window) {
            this.window = window;

            window.notify["is-active"].connect (update_scribble_state);

            init_settings ();
            update_scribble_state ();
        }

        private void init_settings () {
            if (GLib.SettingsSchemaSource.get_default () != null) {
                var schema_source = GLib.SettingsSchemaSource.get_default ();
                if (schema_source != null && schema_source.lookup (APP_ID, true) != null) {
                    settings = new GLib.Settings (APP_ID);
                    settings.bind (
                        KEY_SCRIBBLY,
                        this, "scribble",
                        SettingsBindFlags.DEFAULT
                    );
                }
            }
        }

        private MarkdownBuffer? find_markdown_buffer () {
            if (window == null) {
                return null;
            }
            var child = window.get_child ();
            if (child is Gtk.Box) {
                var box = child as Gtk.Box;
                var current = box.get_first_child ();
                while (current != null) {
                    if (current is Gtk.ScrolledWindow) {
                        var sw = current as Gtk.ScrolledWindow;
                        if (sw.child is Gtk.TextView) {
                            var tv = sw.child as Gtk.TextView;
                            return tv.buffer as MarkdownBuffer;
                        }
                    }
                    current = current.get_next_sibling ();
                }
            }
            return null;
        }

        public void update_scribble_state () {
            if (window == null) {
                return;
            }

            bool is_exempt = _always_visible;
            bool is_scribbled_active = _scribble && !window.is_active && !is_exempt;

            if (_scribble && !is_exempt) {
                window.add_css_class (STYLE_SCRIBBLED);
                if (!window.is_active) {
                    window.add_css_class (STYLE_UNFOCUSED);
                } else {
                    window.remove_css_class (STYLE_UNFOCUSED);
                }
            } else {
                window.remove_css_class (STYLE_SCRIBBLED);
                window.remove_css_class (STYLE_UNFOCUSED);
            }

            var md_buf = find_markdown_buffer ();
            if (md_buf != null) {
                md_buf.set_scribbled (is_scribbled_active);
            }
        }

        ~ScribblyController () {
            if (window != null) {
                window.notify["is-active"].disconnect (update_scribble_state);
                window = null;
            }
            settings = null;
        }
    }
}
