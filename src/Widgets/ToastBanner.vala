/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    /**
     * Floating transient notification banner used across preferences and sticky note views.
     */
    public class ToastBanner : Jots.Bin {
        private Gtk.Revealer revealer;
        private Gtk.Label label;
        private uint timeout_id = 0;

        public string title {
            get { return label.label; }
            set { label.label = value; }
        }

        public ToastBanner () {
            valign = Gtk.Align.START;
            halign = Gtk.Align.CENTER;
            margin_top = SPACING_DOUBLE;

            revealer = new Gtk.Revealer () {
                reveal_child = false,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
            };

            label = new Gtk.Label ("") {
                css_classes = { "app-notification", "frame" },
                margin_start = 12,
                margin_end = 12,
                margin_top = 6,
                margin_bottom = 6
            };
            revealer.child = label;
            child = revealer;
        }

        public void send_notification (uint duration_ms = 3000) {
            revealer.reveal_child = true;
            if (timeout_id != 0) {
                Source.remove (timeout_id);
            }
            timeout_id = Timeout.add_once (duration_ms, on_timeout_expired);
        }

        private void on_timeout_expired () {
            revealer.reveal_child = false;
            timeout_id = 0;
        }

        public override void dispose () {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
            base.dispose ();
        }

        ~ToastBanner () {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
        }
    }
}
