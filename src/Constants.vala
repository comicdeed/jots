/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */
//vala-lint=skip-file

/**
 * I just dump all my constants here
 */
namespace Jots {

    /*************************************************/
    const string COMMUNITY_LINK          = "https://github.com/comicdeed/jots/discussions";

    // signature theme
#if HALLOWEEN
    const Jots.Themes DEFAULT_THEME    = Jots.Themes.ORANGE;
    const string DEFAULT_STYLESHEET     = "io.elementary.stylesheet.orange";
#else
    const Jots.Themes DEFAULT_THEME    = Jots.Themes.BLUEBERRY;
    const string DEFAULT_STYLESHEET     = "io.elementary.stylesheet.blueberry";
#endif

    // in ms
    const int DEBOUNCE                   = 900;

    // CSS
    const string STYLE_DEVEL             = "devel";
    const string STYLE_ANIMATED          = "animated";
    const string STYLE_THEMED            = "themed";
    const string STYLE_THEMEDBUTTON      = "themedbutton";

    // We need to say stop at some point
    const int ZOOM_MAX                   = 300;
    const int DEFAULT_ZOOM               = 100;
    const int ZOOM_MIN                   = 20;
    const bool DEFAULT_MONO              = false;

    // For new stickies
    const int DEFAULT_WIDTH              = 290;
    const int DEFAULT_HEIGHT             = 320;

    // Guardrail limits for external automation and LLM agents
    public const int MAX_NOTE_CONTENT_LENGTH = 10000;
    public const int MAX_NOTE_TITLE_LENGTH   = 120;
    public const int MAX_ACTIVE_NOTES        = 50;
    public const int MAX_SEARCH_RESULTS      = 20;


    const int SPACING_STANDARD           = 5;
    const int SPACING_DOUBLE           = 10;
    const int SPACING_TRIPLE           = 15;

    // Autocomplete save me
    const string KEY_SCRIBBLY           = "scribbly-mode-active";
    const string KEY_HIDEBAR            = "hide-bar";
    const string KEY_LIST               = "list-prefix";
    const string KEY_AUTOSTART          = "autostart";
    const string KEY_CUSTOM_FONTS       = "use-custom-fonts";
    const string KEY_DEFAULT_FONT       = "default-font";
    const string KEY_MONOSPACE_FONT     = "monospace-font";
    const string KEY_JORTS_MIGRATION_PROMPTED = "jorts-migration-prompted";

    // Built-in Cheat Sheet constants
    public const string CHEATSHEET_NOTE_ID   = "jots-cheatsheet";
    public const string CHEATSHEET_TITLE     = "Jots Cheat Sheet";
    public const string CHEATSHEET_CONTENT   = """# Jots Cheat Sheet

### ⌨️ Shortcuts
* **Ctrl + N**: New Sticky Note
* **Ctrl + F**: Search Notes
* **Ctrl + W**: Close Note
* **Ctrl + Shift + Z**: Scribbly (Privacy) Mode
* **Ctrl + Scroll / Pinch**: Zoom Text
* **F1**: Show / Restore this Cheat Sheet

### 📝 Markdown Formatting
* `# H1`, `## H2`, `### H3`
* `**Bold**`, `*Italic*`, `~~Strikethrough~~`
* `- [ ] Task`, `- [x] Completed`
* `> Blockquote`
* ` `code` ` or ``` code blocks ```

### 🤖 AI Automation
* Connect Claude, Cursor, or Gemini CLI via `jots-mcp`.

""";

}