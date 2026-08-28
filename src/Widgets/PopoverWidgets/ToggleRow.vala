/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * A clean GTK4 row with a label and a switch toggle for per-note properties.
     */
    public class ToggleRow : Gtk.Box {

        private Gtk.Label label_widget;
        private Gtk.Switch switch_widget;

        public signal void toggled (bool active);

        public bool active {
            get { return switch_widget.active; }
            set { switch_widget.active = value; }
        }


        public ToggleRow (string label_text, string? tooltip_text = null) {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: SPACING_DOUBLE,
                margin_start: SPACING_DOUBLE,
                margin_end: SPACING_DOUBLE,
                hexpand: true
            );

            label_widget = new Gtk.Label (label_text) {
                xalign = 0.0f,
                hexpand = true
            };

            switch_widget = new Gtk.Switch () {
                valign = Gtk.Align.CENTER
            };

            if (tooltip_text != null) {
                label_widget.tooltip_text = tooltip_text;
                switch_widget.tooltip_text = tooltip_text;
            }

            switch_widget.notify["active"].connect (on_switch_active_changed);

            append (label_widget);
            append (switch_widget);
        }

        private void on_switch_active_changed () {
            toggled (switch_widget.active);
        }

        ~ToggleRow () {
            switch_widget.notify["active"].disconnect (on_switch_active_changed);
        }
    }
}
