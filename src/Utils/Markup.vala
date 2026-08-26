/*
 * Copyright (C) 2026 Dino Korah
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

namespace Jots.Util {
    public string markup_accel_tooltip (string label, string? accel) {
        if (accel == null || accel.length == 0) {
            return Markup.escape_text (label);
        }
        return "%s <small><span fgalpha=\"60%%\">%s</span></small>".printf (
            Markup.escape_text (label),
            Markup.escape_text (accel)
        );
    }
}
