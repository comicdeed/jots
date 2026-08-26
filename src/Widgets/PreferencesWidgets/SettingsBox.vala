/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

/**
* Switch and its explanatory text
*/
public class Jots.SettingsBox : Gtk.Box {

    public string text {get; construct;}
    public string? description {get; construct;}
    public Gtk.Widget widget {get; construct;}

    public SettingsBox (string text, string? description, Gtk.Widget widget) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            spacing: SPACING_STANDARD,
            text: text,
            description: description,
            widget: widget
        );
    }

    construct {
        widget.halign = Gtk.Align.END;
        widget.hexpand = true;
        widget.valign = Gtk.Align.CENTER;

        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) {
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        var title_label = new Gtk.Label (text) {
            use_underline = true,
            mnemonic_widget = widget,
            xalign = 0.0f,
            halign = Gtk.Align.START
        };
        title_label.add_css_class ("heading");
        text_box.append (title_label);

        if (description != null) {
            var desc_label = new Gtk.Label (description) {
                xalign = 0.0f,
                halign = Gtk.Align.START,
                wrap = true
            };
            desc_label.add_css_class ("dim-label");
            text_box.append (desc_label);
        }

        append (text_box);
        append (widget);
    }
}
