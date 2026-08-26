/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

/*

/**
* I just dont wanna rewrite the same button over and over
*/
public class Jots.ColorPill : Gtk.ToggleButton {

    public Jots.Themes color { get; construct set; }
    public bool is_first { get; set; default = false; }
    public bool is_last { get; set; default = false; }

    private Gtk.DrawingArea drawing_area;

    public ColorPill (Themes color, Gtk.ToggleButton? group_member = null, bool first = false, bool last = false) {
        Object (
            color: color,
            group: group_member,
            hexpand: true,
            vexpand: true
        );

        this.is_first = first;
        this.is_last = last;

        add_css_class ("flat");
        add_css_class ("color-pill-btn");

        tooltip_text = color.to_nicename ();

        action_name = "popover.prefers-accent-color";
        action_target = new Variant.int32 (color);

        drawing_area = new Gtk.DrawingArea () {
            hexpand = true,
            vexpand = true
        };
        drawing_area.set_content_height (26);
        drawing_area.set_draw_func (draw_pill);

        set_child (drawing_area);

        toggled.connect (on_toggled);
    }

    private void on_toggled () {
        if (drawing_area != null) {
            drawing_area.queue_draw ();
        }
    }

    private void draw_pill (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        double r = 6.0;
        double w = (double) width;
        double h = (double) height;

        cr.new_sub_path ();
        if (is_first && is_last) {
            cr.arc (r, r, r, Math.PI, 1.5 * Math.PI);
            cr.arc (w - r, r, r, 1.5 * Math.PI, 2.0 * Math.PI);
            cr.arc (w - r, h - r, r, 0, 0.5 * Math.PI);
            cr.arc (r, h - r, r, 0.5 * Math.PI, Math.PI);
            cr.close_path ();
        } else if (is_first) {
            cr.arc (r, r, r, Math.PI, 1.5 * Math.PI);
            cr.line_to (w, 0);
            cr.line_to (w, h);
            cr.arc (r, h - r, r, 0.5 * Math.PI, Math.PI);
            cr.close_path ();
        } else if (is_last) {
            cr.move_to (0, 0);
            cr.arc (w - r, r, r, 1.5 * Math.PI, 2.0 * Math.PI);
            cr.arc (w - r, h - r, r, 0, 0.5 * Math.PI);
            cr.line_to (0, h);
            cr.close_path ();
        } else {
            cr.rectangle (0, 0, w, h);
        }

        // 1. Fill base theme color
        Gdk.RGBA base_color = {};
        base_color.parse (color.to_hex_color ());
        Gdk.cairo_set_source_rgba (cr, base_color);
        cr.fill_preserve ();

        // 2. Subtle 1px boundary stroke
        cr.set_source_rgba (0, 0, 0, 0.35);
        cr.set_line_width (1.0);
        cr.stroke ();

        // 3. Checked / Active State: Inset white ring with matching accent core
        if (this.active) {
            cr.save ();
            double cx = w / 2.0;
            double cy = h / 2.0;
            double ring_radius = double.min (w, h) / 2.0 - 3.5;
            if (ring_radius > 2.0) {
                cr.arc (cx, cy, ring_radius, 0, 2 * Math.PI);
                cr.set_source_rgba (1.0, 1.0, 1.0, 0.95);
                cr.fill ();

                cr.arc (cx, cy, ring_radius - 2.5, 0, 2 * Math.PI);
                Gdk.cairo_set_source_rgba (cr, base_color);
                cr.fill ();
            }
            cr.restore ();
        }
    }
}
