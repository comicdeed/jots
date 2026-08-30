/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

/**
* A box mimicking the one in elementary OS Appearance settings page
* It shows discrete circular color pills with matching outer selection rings
*/
public class Jots.ColorBox : Gtk.Box {

    public SimpleAction accent_color_action;

    public Jots.Themes color {
        get { return (Jots.Themes) accent_color_action.get_state ().get_int32 (); }
        set {
            if (accent_color_action != null) {
                accent_color_action.set_state (new Variant.int32 (value));
            }
            if (drawing_area != null) {
                drawing_area.queue_draw ();
            }
        }
    }

    public signal void theme_changed (Themes selected);

    private Gtk.DrawingArea drawing_area;
    private Themes[] themes;
    private int hovered_index = -1;
    private const int BOX_WIDTH = 264;
    private const int BOX_HEIGHT = 30;
    private const double PILL_RADIUS = 8.5;

    public ColorBox () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            accessible_role: Gtk.AccessibleRole.LIST,
            halign: Gtk.Align.CENTER,
            margin_start: SPACING_DOUBLE,
            margin_end: SPACING_DOUBLE
        );
    }

    construct {
        add_css_class ("color-box");

        themes = Themes.all ();

        drawing_area = new Gtk.DrawingArea () {
            cursor = new Gdk.Cursor.from_name ("pointer", null),
            focusable = true
        };
        drawing_area.set_content_width (BOX_WIDTH);
        drawing_area.set_content_height (BOX_HEIGHT);
        drawing_area.set_draw_func (draw_colorbox);

        // Click Gesture
        var click_gesture = new Gtk.GestureClick ();
        click_gesture.pressed.connect (on_click_pressed);
        drawing_area.add_controller (click_gesture);

        // Motion / Hover / Tooltip Controller
        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.motion.connect (on_mouse_motion);
        motion_controller.leave.connect (on_mouse_leave);
        drawing_area.add_controller (motion_controller);

        append (drawing_area);

        accent_color_action = new SimpleAction.stateful ("prefers-accent-color", GLib.VariantType.INT32, new Variant.int32 (Themes.IDK));
        var action_group = new SimpleActionGroup ();
        action_group.add_action (accent_color_action);
        insert_action_group ("popover", action_group);

        accent_color_action.activate.connect (set_broadcast);
    }

    private void on_click_pressed (int n_press, double x, double y) {
        int n = themes.length;
        if (n == 0) {
            return;
        }
        double cur_width = (double) drawing_area.get_width ();
        double step = (n > 1) ? (cur_width - 2.0 * (PILL_RADIUS + 5.0)) / (n - 1) : 0.0;
        double start_x = PILL_RADIUS + 5.0;

        int index = (step > 0.0) ? (int) ((x - start_x + step / 2.0) / step) : 0;
        if (index >= 0 && index < n) {
            double cx = start_x + index * step;
            double cy = (double) drawing_area.get_height () / 2.0;
            double dx = x - cx;
            double dy = y - cy;
            if (dx * dx + dy * dy <= (PILL_RADIUS + 5.0) * (PILL_RADIUS + 5.0)) {
                set_broadcast (new Variant.int32 (themes[index]));
                drawing_area.queue_draw ();
            }
        }
    }

    private void on_mouse_motion (double x, double y) {
        int n = themes.length;
        if (n == 0) {
            return;
        }
        double cur_width = (double) drawing_area.get_width ();
        double step = (n > 1) ? (cur_width - 2.0 * (PILL_RADIUS + 5.0)) / (n - 1) : 0.0;
        double start_x = PILL_RADIUS + 5.0;

        int index = (step > 0.0) ? (int) ((x - start_x + step / 2.0) / step) : 0;
        if (index >= 0 && index < n) {
            double cx = start_x + index * step;
            double cy = (double) drawing_area.get_height () / 2.0;
            double dx = x - cx;
            double dy = y - cy;
            if (dx * dx + dy * dy <= (PILL_RADIUS + 5.0) * (PILL_RADIUS + 5.0)) {
                if (hovered_index != index) {
                    hovered_index = index;
                    drawing_area.tooltip_text = themes[index].to_nicename ();
                    drawing_area.queue_draw ();
                }
                return;
            }
        }
        if (hovered_index != -1) {
            hovered_index = -1;
            drawing_area.tooltip_text = null;
            drawing_area.queue_draw ();
        }
    }

    private void on_mouse_leave () {
        if (hovered_index != -1) {
            hovered_index = -1;
            drawing_area.tooltip_text = null;
            drawing_area.queue_draw ();
        }
    }

    private void draw_colorbox (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        int n = themes.length;
        if (n == 0) {
            return;
        }
        double step = (n > 1) ? ((double) width - 2.0 * (PILL_RADIUS + 5.0)) / (n - 1) : 0.0;
        double start_x = PILL_RADIUS + 5.0;
        double cy = (double) height / 2.0;
        var current_theme = this.color;

        for (int i = 0; i < n; i++) {
            double cx = start_x + i * step;

            Gdk.RGBA color_rgba = {};
            color_rgba.parse (themes[i].to_hex_color ());

            // 1. Base circular color pill
            cr.arc (cx, cy, PILL_RADIUS, 0, 2 * Math.PI);
            Gdk.cairo_set_source_rgba (cr, color_rgba);
            cr.fill_preserve ();

            // Subtle dark boundary stroke
            cr.set_source_rgba (0, 0, 0, 0.25);
            cr.set_line_width (1.0);
            cr.stroke ();

            // 2. Hover ring
            if (i == hovered_index && themes[i] != current_theme) {
                cr.arc (cx, cy, PILL_RADIUS + 2.5, 0, 2 * Math.PI);
                Gdk.cairo_set_source_rgba (cr, color_rgba);
                cr.set_line_width (1.5);
                cr.stroke ();
            }

            // 3. Active / Selected: Signature outer matching accent ring + white gap
            if (themes[i] == current_theme) {
                // White separation ring
                cr.arc (cx, cy, PILL_RADIUS + 2.0, 0, 2 * Math.PI);
                cr.set_source_rgba (1.0, 1.0, 1.0, 1.0);
                cr.set_line_width (2.0);
                cr.stroke ();

                // Matching outer theme accent ring
                cr.arc (cx, cy, PILL_RADIUS + 4.0, 0, 2 * Math.PI);
                Gdk.cairo_set_source_rgba (cr, color_rgba);
                cr.set_line_width (2.0);
                cr.stroke ();
            }
        }
    }

    // Ignore if user switches from same value to same value
    // Only send signal if it is a user action, to avoid a deathloop if theme is changed elsewhere
    private void set_broadcast (GLib.Variant? value) {
        if (!accent_color_action.get_state ().equal (value)) {
            accent_color_action.set_state (value);
            theme_changed ((Jots.Themes) color);
            if (drawing_area != null) {
                drawing_area.queue_draw ();
            }
        }
    }
}
