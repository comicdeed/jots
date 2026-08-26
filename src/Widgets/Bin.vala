/*
 * Copyright (C) 2026 Dino Korah
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

public class Jots.Bin : Gtk.Widget {
    private Gtk.Widget? _child = null;

    public Gtk.Widget? child {
        get { return _child; }
        set {
            if (_child == value) {
                return;
            }
            if (_child != null) {
                _child.unparent ();
            }
            _child = value;
            if (_child != null) {
                _child.set_parent (this);
            }
        }
    }

    construct {
        layout_manager = new Gtk.BinLayout ();
    }

    public override void dispose () {
        if (_child != null) {
            _child.unparent ();
            _child = null;
        }
        base.dispose ();
    }
}
