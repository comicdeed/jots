/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 *                          2026 Dino Korah (github.com/codemedic)
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
    const Jots.Themes DEFAULT_THEME    = Jots.Themes.TANGERINE;
    const string DEFAULT_STYLESHEET     = "io.elementary.stylesheet.orange";
#else
    const Jots.Themes DEFAULT_THEME    = Jots.Themes.SEA_GLASS;
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

    // Application actions
    public const string ACTION_APP_PREFIX        = "app.";
    public const string ACTION_SHOW_PREFERENCES  = "show_preferences";
    public const string ACTION_QUIT              = "quit";
    const string KEY_AUTOSTART          = "autostart";
    const string KEY_CUSTOM_FONTS       = "use-custom-fonts";
    const string KEY_DEFAULT_FONT       = "default-font";
    const string KEY_MONOSPACE_FONT     = "monospace-font";
    const string KEY_JORTS_MIGRATION_PROMPTED = "jorts-migration-prompted";
    const string KEY_BACKUP_SYNC_ENABLED = "backup-sync-enabled";
    const string KEY_BACKUP_SYNC_REMOTE_URL = "backup-sync-remote-url";
    const string KEY_BACKUP_SYNC_CADENCE = "backup-sync-cadence";
    const string KEY_BACKUP_SYNC_STATUS = "backup-sync-status";
    const string KEY_BACKUP_SYNC_LAST_SYNC = "backup-sync-last-sync";
    const string KEY_BACKUP_SYNC_GITIGNORE_SHA = "backup-sync-gitignore-sha";

    const string BACKUP_STATUS_DISABLED = "Backup disabled";
    const string BACKUP_STATUS_PREPARING = "Preparing backup repository";
    const string BACKUP_STATUS_REPOSITORY_READY = "Backup repository ready";
    const string BACKUP_STATUS_PENDING = "Changes detected; backup sync setup in progress";
    const string BACKUP_STATUS_LOCAL_COMMIT_CREATED = "Backup updated locally";
    const string BACKUP_STATUS_EXTERNAL_CHANGES_DETECTED = "External changes detected in notes repository";
    const string BACKUP_STATUS_REMOTE_DIVERGED = "Remote changes detected; sync update needed";
    const string BACKUP_STATUS_REMOTE_NOT_CONFIGURED = "Set a remote repository URL to enable sync";
    const string BACKUP_STATUS_FINALIZING_LOCAL_CHANGES = "Finalizing local backup changes before remote sync";
    const string BACKUP_STATUS_SYNC_REQUEST_QUEUED = "Sync request queued; current sync still in progress";
    const string BACKUP_STATUS_SYNCING_REMOTE = "Syncing backup with remote repository";
    const string BACKUP_STATUS_REMOTE_RETRY_SCHEDULED = "Remote sync retry scheduled after recent failure";
    const string BACKUP_STATUS_REMOTE_SYNCED = "Backup synchronized with remote repository";
    const string BACKUP_STATUS_TESTING_REMOTE = "Checking remote repository connectivity";
    const string BACKUP_STATUS_REMOTE_REACHABLE = "Remote repository is reachable";
    const string BACKUP_STATUS_REMOTE_UNREACHABLE = "Remote repository check failed";
    const string BACKUP_STATUS_GITIGNORE_RESTORED = "Managed .gitignore restored";
    const string BACKUP_STATUS_ERROR = "Backup setup failed";

    // Built-in Cheat Sheet constants
    public const string CHEATSHEET_NOTE_ID   = "jots-cheatsheet";
    public const string CHEATSHEET_TITLE     = "Jots Cheat Sheet";
    public const string CHEATSHEET_CONTENT   = """# Jots Cheat Sheet

### ⌨️ Shortcuts
* **Ctrl + N**: New Sticky Note
* **Ctrl + F**: Search Notes
* **Ctrl + W**: Close Note
* **Ctrl + H**: Scribbly (Privacy) Mode
* **Ctrl + V**: Smart Paste (Markdown & Rich Text)
* **Ctrl + Shift + V**: Paste Without Formatting (Raw)
* **Shift + F12**: Toggle List
* **Ctrl + D** / **Ctrl + Enter**: Toggle Checklist
* **Ctrl + M**: Toggle Monospace
* **Ctrl + T**: Toggle Action Bar Auto-Hide
* **Ctrl + Scroll / Pinch**: Zoom Text
* **F1**: Show / Restore this Cheat Sheet

### 📝 Markdown Formatting
* `# H1`, `## H2`, `### H3`
* `**Bold**`, `*Italic*`, `~~Strikethrough~~`
* `- [ ] Task`, `- [x] Completed`
* `- List Item` (Smart Lists)
* `> Blockquote`
* ` `code` ` or ``` code blocks ```
* `[Title](https://...)` Links

### 🤖 AI Automation
* Connect Claude, Cursor, Devin, or Antigravity via `jots-mcp`.

""";

}
