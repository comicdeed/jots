/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
 */

// vala-lint=skip-file

/*************************************************/
/**
* A register of all themes we have
*/
public enum Jots.Themes {
    BANANA,
    TANGERINE,
    PEACH,
    WATERMELON,
    BUBBLEGUM,
    LAVENDER,
    OCEAN,
    SEA_GLASS,
    MINT,
    PEAR,
    PEBBLE,
    GRAPHITE,
    IDK;

    /*************************************************/
    /**
    * for use in CSS. Ex: @BANANA_500
    */
    public string to_string () {
        switch (this) {
            case BANANA:        return "BANANA";
            case TANGERINE:     return "TANGERINE";
            case PEACH:         return "PEACH";
            case WATERMELON:    return "WATERMELON";
            case BUBBLEGUM:     return "BUBBLEGUM";
            case LAVENDER:      return "LAVENDER";
            case OCEAN:         return "OCEAN";
            case SEA_GLASS:     return "SEA_GLASS";
            case MINT:          return "MINT";
            case PEAR:          return "PEAR";
            case PEBBLE:        return "PEBBLE";
            case GRAPHITE:      return "GRAPHITE";
            case IDK:           return (Jots.Themes.random_theme (NoteData.latest_theme)).to_string ();
            default: return "PEBBLE";
        }
    }

    /*************************************************/
    /**
    * for use to pinpoint to the correct CSS class
    */
    public string to_css_class () {
        return this.to_string ().ascii_down ();
    }

    /*************************************************/
    /**
    * vivid picker chip color, for selection controls/swatches only (not text or backgrounds)
    */
    public string to_hex_color () {
        switch (this) {
            case BANANA:        return "#FFB300";
            case TANGERINE:     return "#FF6D00";
            case PEACH:         return "#FF5252";
            case WATERMELON:    return "#D50000";
            case BUBBLEGUM:     return "#F50057";
            case LAVENDER:      return "#AA00FF";
            case OCEAN:         return "#2979FF";
            case SEA_GLASS:     return "#00BFA5";
            case MINT:          return "#00C853";
            case PEAR:          return "#AEEA00";
            case PEBBLE:        return "#9E9E9E";
            case GRAPHITE:      return "#546E7A";
            default:            return "#9E9E9E";
        }
    }

    /*************************************************/
    /**
    * for the UI, as translated, proper name
    */
    public string to_nicename () {
        switch (this) {
            //TRANSLATORS: These are the names of the Jots sticky note color palette
            // They are shown in a tooltip when the user hovers over a little colored pillbutton
            case BANANA:        return _("Banana");
            case TANGERINE:     return _("Tangerine");
            case PEACH:         return _("Peach");
            case WATERMELON:    return _("Watermelon");
            case BUBBLEGUM:     return _("Bubblegum");
            case LAVENDER:      return _("Lavender");
            case OCEAN:         return _("Ocean");
            case SEA_GLASS:     return _("Sea Glass");
            case MINT:          return _("Mint");
            case PEAR:          return _("Pear");
            case PEBBLE:        return _("Pebble");
            case GRAPHITE:      return _("Graphite");
            case IDK:           return _("No preference, random each time");
            default:            return _("Pebble");
        }
    }

    /*************************************************/
    /**
    * convenient list of all supported themes
    */
    public static Themes[] all () {
        return {BANANA, TANGERINE, PEACH, WATERMELON, BUBBLEGUM, LAVENDER, OCEAN, SEA_GLASS, MINT, PEAR, PEBBLE, GRAPHITE};
    }

    /*************************************************/
    /**
    * convenient list of all supported themes
    */
    public static string[] all_string () {
        return {"BANANA", "TANGERINE", "PEACH", "WATERMELON", "BUBBLEGUM", "LAVENDER", "OCEAN", "SEA_GLASS", "MINT", "PEAR", "PEBBLE", "GRAPHITE"};
    }

    /*************************************************/
    /**
    * Used for new notes without data. Optionally allows to skip one
    * This avoids generating notes "randomly" with the same themes, which would be boring
    */
    public static Jots.Themes random_theme (Jots.Themes? skip_theme = null) {
        Gee.ArrayList<Jots.Themes> themes = new Gee.ArrayList<Jots.Themes> ();
        themes.add_all_array (Jots.Themes.all ());

        if (skip_theme != null) {
            themes.remove (skip_theme);
        }

        var random_in_range = Random.int_range (0, themes.size);
        return themes[random_in_range];
    }

    /*************************************************/
    /**
    * Parse theme from string case-insensitively.
    * Also accepts the pre-1.x palette names as deprecated aliases for old MCP clients and notes.
    */
    public static Themes from_string (string? name, Themes fallback = Themes.PEBBLE) {
        if (name == null) {
            return fallback;
        }
        var lower = name.strip ().ascii_down ();
        switch (lower) {
            case "banana":      return Themes.BANANA;
            case "tangerine":   return Themes.TANGERINE;
            case "peach":       return Themes.PEACH;
            case "watermelon":  return Themes.WATERMELON;
            case "bubblegum":   return Themes.BUBBLEGUM;
            case "lavender":    return Themes.LAVENDER;
            case "ocean":       return Themes.OCEAN;
            case "sea glass":
            case "sea_glass":
            case "seaglass":    return Themes.SEA_GLASS;
            case "mint":        return Themes.MINT;
            case "pear":        return Themes.PEAR;
            case "pebble":      return Themes.PEBBLE;
            case "graphite":    return Themes.GRAPHITE;
            // Deprecated pre-1.x palette aliases
            case "blueberry":   return Themes.OCEAN;
            case "lime":        return Themes.PEAR;
            case "orange":      return Themes.TANGERINE;
            case "strawberry":  return Themes.WATERMELON;
            case "grape":       return Themes.LAVENDER;
            case "cocoa":       return Themes.GRAPHITE;
            case "slate":       return Themes.PEBBLE;
            case "latte":       return Themes.PEACH;
            default:            return fallback;
        }
    }

    /*************************************************/
    /**
    * Resolves the pre-1.x numeric `color:` ordinal (0=Blueberry .. 10=Latte) to its new
    * equivalent. Fixed lookup independent of the current enum's ordinal, so old notes and
    * legacy Jorts JSON imports keep their original visual color after the palette migration.
    */
    public static Themes from_legacy_ordinal (int ordinal, Themes fallback = Themes.PEBBLE) {
        switch (ordinal) {
            case 0:  return Themes.OCEAN;      // Blueberry
            case 1:  return Themes.MINT;       // Mint
            case 2:  return Themes.PEAR;       // Lime
            case 3:  return Themes.BANANA;     // Banana
            case 4:  return Themes.TANGERINE;  // Orange
            case 5:  return Themes.WATERMELON; // Strawberry
            case 6:  return Themes.BUBBLEGUM;  // Bubblegum
            case 7:  return Themes.LAVENDER;   // Grape
            case 8:  return Themes.GRAPHITE;   // Cocoa
            case 9:  return Themes.PEBBLE;     // Slate
            case 10: return Themes.PEACH;      // Latte
            default: return fallback;
        }
    }
}
