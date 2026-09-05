# Product Roadmap and Feature Candidates

A curated backlog of architectural enhancements, capabilities, and feature candidates graded against the [Idea Evaluation and Grading Framework](development/ideas-grading.md).

---

## Table of Contents

- [Product Roadmap and Feature Candidates](#product-roadmap-and-feature-candidates)
  - [Table of Contents](#table-of-contents)
  - [1. Evaluation Summary \& Score Matrix](#1-evaluation-summary--score-matrix)
  - [2. Fast-Track Quality \& Bug Polish (v1.3.x Target)](#2-fast-track-quality--bug-polish-v13x-target)
  - [3. High-Priority Initiatives (Tier 1)](#3-high-priority-initiatives-tier-1)
    - [3.1 Note Organizer and Management Interface](#31-note-organizer-and-management-interface)
    - [3.2 List & Checklist Typography & Keyboard Ergonomics](#32-list--checklist-typography--keyboard-ergonomics)
    - [3.3 Free-Form In-Text Tagging with Autocompletion](#33-free-form-in-text-tagging-with-autocompletion)
  - [4. Planned Backlog (Tier 2)](#4-planned-backlog-tier-2)
    - [4.1 Intelligent Note Deletion Safety & Trash Lifecycle](#41-intelligent-note-deletion-safety--trash-lifecycle)
    - [4.2 Bidirectional Note Linking (`[[Note Title]]`)](#42-bidirectional-note-linking-note-title)
    - [4.3 AppImage Provenance and Signature Verification](#43-appimage-provenance-and-signature-verification)
    - [4.4 AppImage Update Information Embedding](#44-appimage-update-information-embedding)
  - [5. Deferred / Incubating Concepts (Tier 4)](#5-deferred--incubating-concepts-tier-4)
    - [5.1 Google Keep Backend Synchronization](#51-google-keep-backend-synchronization)
    - [5.2 Windows Backup and Sync Compatibility Hardening](#52-windows-backup-and-sync-compatibility-hardening)
  - [6. Completed Initiatives](#6-completed-initiatives)
    - [6.1 Native Model Context Protocol (MCP) Server](#61-native-model-context-protocol-mcp-server)
    - [6.2 Markdown Storage with YAML Front Matter \& Live Rendering](#62-markdown-storage-with-yaml-front-matter--live-rendering)
    - [6.3 Typography Customization \& Obfuscated Scribbly Mode](#63-typography-customization--obfuscated-scribbly-mode)
    - [6.4 Local Full-Text Search \& Interactive Popover](#64-local-full-text-search--interactive-popover)
    - [6.5 Daily Routine Adoption \& Presence](#65-daily-routine-adoption--presence)
    - [6.6 Automated Git Backup and Remote Synchronization](#66-automated-git-backup-and-remote-synchronization)
    - [6.7 Focus-Aware Minimalist Desktop Chrome](#67-focus-aware-minimalist-desktop-chrome)
    - [6.8 Retire List Item Prefix Preference](#68-retire-list-item-prefix-preference)

---

## 1. Evaluation Summary & Score Matrix

The score matrix is curated to include only non-completed roadmap candidates (active, planned, deferred, or incubating). Once an initiative ships, remove it from this matrix and keep its historical record in [Section 6: Completed Initiatives](#6-completed-initiatives).

| Feature Concept | Impact (40%) | Alignment (35%) | Feasibility (25%) | Composite Score | Tier / Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Note Organizer & Management Interface** | 4.4 | 4.6 | 4.2 | **4.42** | 🟢 Tier 1 (Active Priority) |
| **List & Checklist Ergonomics & Typography** | 4.2 | 4.5 | 4.0 | **4.26** | 🟢 Tier 1 (Active Priority) |
| **Free-Form In-Text Tagging (`#tag`)** | 4.0 | 4.0 | 3.8 | **3.95** | 🟢 Tier 1 (Active Priority) |
| **Intelligent Deletion Safety & Trash Lifecycle** | 4.0 | 4.0 | 3.8 | **3.95** | 🟢 Tier 1 (Active Priority) |
| **AppImage Provenance & Signatures** | 3.2 | 4.4 | 4.0 | **3.92** | 🟡 Tier 2 (Planned Backlog) |
| **AppImage Update Info Embedding** | 3.0 | 4.2 | 4.5 | **3.72** | 🟡 Tier 2 (Planned Backlog) |
| **Bidirectional Note Linking (`[[Note]]`)** | 3.8 | 3.6 | 3.4 | **3.63** | 🟡 Tier 2 (Planned Backlog) |
| **Google Keep Backend Sync** | 3.0 | 1.8 | 1.2 | **2.13** | 🔴 Tier 4 (Deferred) |
| **Windows Backup & Sync Compatibility Hardening** | 1.9 | 2.0 | 1.4 | **1.79** | 🔴 Tier 4 (Deferred, Lowest Priority) |

---

## 2. Fast-Track Quality & Bug Polish (v1.3.x Target)

Targeted, self-contained fixes and ergonomics refinements to address active friction points:

* ✅ **Scroll Zoom Modifier Desynchronization**: Inspect `scroll_controller.get_current_event_state()` and `CONTROL_MASK` directly on scroll events, eliminating stuck zoom triggers caused by dropped key release events (`45e899a`).
* ✅ **Git Backup Cheat Sheet Exclusion**: Explicitly exclude ephemeral cheat sheet notes (`Constants.CHEATSHEET_NOTE_ID`) in `GitSyncService.should_sync_note()` and `.gitignore` so tutorial notes never create Git commits or pollute remote repositories (`60837e0`).
* ✅ **Title Editing Dark Mode Pill & Dismiss**: Converted title focus styling to rounded background pills (`border-radius: 6px`), disabled dark mode text-shadow emboss, and added header margin click dismissal via `headerbar.pick (x, y)` (`081c612`).
* ✅ **Uniform 4-Corner Window Rounding**: Harmonized `border-radius: 12px` across all four window corners and top/bottom child widgets in `Themes.css` (`d0deeba`).
* ✅ **Read-Only / Lock Mode Mutation Guards**: Blocked programmatic buffer modifications (auto-list continuation on <kbd>Enter</kbd>, paste on <kbd>Ctrl+V</kbd>, emoji insertion) when notes are locked (`5efc27b`).
* ✅ **Scrolled Window Clean Canvas & Floating Scrollbars**: Completely disabled obscuring `undershoot` / `overshoot` gradient overlays in favor of clean canvas edges and minimal floating scrollbars (`e3a4967`).

---

## 3. High-Priority Initiatives (Tier 1)

### 3.1 Note Organizer and Management Interface
* **Score**: `4.42` (Tier 1: Active Priority)
* **Goal**: Provide an optional central manager interface (`Jots.LibraryWindow`) to organize, filter, hide/close, and restore notes without cluttering the desktop canvas.
* **Implementation Strategy**:
  * **Active vs. Stored / Hidden Lifecycle**: Distinguish between "Pinned to Desktop" (active floating windows) and "Stored in Library" (persisted `.md` files hidden from desktop view).
  * **Tag Filtering & Categories**: Display aggregated `#tag` pills and category filters directly in the library view.
  * **Card Grid & List View**: Visual note cards with theme color accents, titles, modification dates, and search snippets.
  * **Trash & Recovery**: Integrate soft-deletion and safe restoration.

### 3.2 List & Checklist Typography & Keyboard Ergonomics
* **Score**: `4.26` (Tier 1: Active Priority)
* **Goal**: Elevate list and task ergonomics with hanging indents for wrapped items, real-time prefix dimming, multi-line edit stability, and dedicated checklist toggle shortcuts.
* **Implementation Strategy**:
  * **Hanging Indentation**: Configure `GtkTextTag` `left_margin` and negative `indent` in `MarkdownBuffer` so multi-line list entries wrap flush with text rather than falling beneath `- [ ]` or `* `.
  * **Unified Prefix Dimming**: Extend subtle subdued styling to all list markers (`-`, `*`, `+`, `1.`), harmonizing bullet styling with checkbox prefixes.
  * **Real-Time Prefix Tagging**: Apply prefix styling immediately upon typing `- [ ] ` or `* ` rather than waiting for post-solidification or focus change.
  * **Buffer Edit Stability**: Harden tag re-application boundaries so modifying lines in the middle of a note preserves correct indentation and dimming for following lines.
  * **Keyboard Toggle**: Implement a keyboard shortcut (<kbd>Ctrl</kbd>+<kbd>Enter</kbd> or <kbd>Ctrl</kbd>+<kbd>D</kbd>) to toggle `- [ ]` $\leftrightarrow$ `- [x]` on the current line or active selection.

### 3.3 Free-Form In-Text Tagging with Autocompletion
* **Score**: `3.95` (Tier 1: Active Priority)
* **Goal**: Allow free-form `#tag` definitions anywhere in note bodies with dynamic tag indexing, autocompletion popups, and sidebar filter synergy.
* **Implementation Strategy**:
  * Leverage `GtkTextTag` in `MarkdownBuffer` (`TAG_TAG`) for subtle pastel highlight badge styling.
  * Index active tags in memory via `NoteManager` to power autocompletion and category filters in the Note Organizer.

---

## 4. Planned Backlog (Tier 2)

### 4.1 Intelligent Note Deletion Safety & Trash Lifecycle
* **Score**: `3.95` (Tier 1 / Tier 2)
* **Goal**: Prevent accidental loss of substantive notes while streamlining single-click dismissal for blank/ephemeral notes, combined with soft-delete archiving and Git sync safety checks.
* **Implementation Strategy**:
  * **Empty Note Fast-Discard**: Newly created notes with empty or zero content dismiss instantly without confirmation alerts.
  * **Content-Aware Confirmation**: Scale confirmation prompts based on note size (standard alert for short notes; title typing or elevated warning for notes with > X words).
  * **Git Sync Unsaved Check**: When Git Backup is active, check local Git repository status and warn explicitly if deleting notes with uncommitted changes.
  * **Soft-Delete Archive (`.trash/`)**: Move deleted `.md` files to a `.trash/` subfolder rather than instant permanent deletion, enabling easy recovery from the Note Organizer.

### 4.2 Bidirectional Note Linking (`[[Note Title]]`)
* **Score**: `3.63` (Tier 2: Planned Backlog)
* **Goal**: Inter-note navigation using wiki-style `[[Note Title]]` links that open or focus target sticky notes on click.
* **Implementation Strategy**:
  * Recognize `[[...]]` patterns in `MarkdownBuffer` and render as clickable note links.
  * Resolve target note by UUID or Title in `NoteManager`.

### 4.3 AppImage Provenance and Signature Verification
* **Score**: `3.92` (Tier 2: Planned Backlog)
* **Goal**: Improve release trust and provenance by cryptographically signing shipped AppImages and publishing verification material.
* **Implementation Strategy**:
  * Create a dedicated Jots release-signing GPG key and publish the armored public key.
  * Enable AppImage signing in `packaging/appimage/build-appimage.sh` for both `x86_64` and `aarch64` outputs.
  * Attach signature verification instructions (`VERIFY.md`) to GitHub releases.

### 4.4 AppImage Update Information Embedding
* **Score**: `3.72` (Tier 2: Planned Backlog)
* **Goal**: Embed AppImage update information into released binaries for efficient delta auto-updates via `AppImageUpdate` / `zsyncmake`.
* **Implementation Strategy**:
  * Use the `gh-releases-zsync` format pointing to the GitHub Releases page.
  * Inject `.upd-info` ELF section via `appimagetool -u` in `build-appimage.sh`.
  * Extend `.github/workflows/release.yml` to generate and upload matching `.zsync` sidecar files.

---

## 5. Deferred / Incubating Concepts (Tier 4)

### 5.1 Google Keep Backend Synchronization
* **Score**: `2.13` (Tier 4: Deferred)
* **Rationale**: Google restricts the official Keep REST API strictly to Google Workspace Enterprise domains. Consumer accounts require unofficial scraping libraries which are fragile and break offline-first principles.

### 5.2 Windows Backup and Sync Compatibility Hardening
* **Score**: `1.79` (Tier 4: Deferred, Lowest Priority)
* **Goal**: Improve out-of-the-box reliability for Backup & Sync on Windows builds by reducing host-environment assumptions around Git availability and credential setup.

---

## 6. Completed Initiatives

### 6.1 Native Model Context Protocol (MCP) Server
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Implemented standalone native Vala `jots-mcp` executable (`src/Mcp/`) and D-Bus IPC service (`io.github.comicdeed.jots.Notes`), providing line-delimited JSON-RPC 2.0 stdio communication for AI assistants (Claude Desktop, Cursor, Devin Desktop, Antigravity) with zero external Python dependencies.
* **Documentation**: See [`docs/development/mcp-server.md`](development/mcp-server.md) and [`docs/user-guide.md`](user-guide.md#6-ai-assistant--mcp-integration).

### 6.2 Markdown Storage with YAML Front Matter & Live Rendering
* **Status**: ✅ **Completed** (v1.0.0, enhanced in v1.3.0)
* **Summary**: Replaced monolithic JSON storage with human-readable `.md` files containing YAML front-matter headers. Implemented live native `MarkdownBuffer` supporting real-time syntax highlighting for headings (`#`, `##`, `###`), bold/italic formatting, checklists (`- [ ]`, `- [x]`), blockquotes (`>`), code spans, code fences, and clickable links. Enhanced in v1.3.0 with resilient clipboard paste normalization that converts rich-text/HTML and normalizes loose Markdown while protecting code fences.
* **Documentation**: See [`docs/architecture.md`](architecture.md#32-markdown-storage-and-serialization) and [`docs/user-guide.md`](user-guide.md#4-markdown-formatting--live-rendering).

### 6.3 Typography Customization & Obfuscated Scribbly Mode
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Added global font family and font size preferences via `Gtk.FontDialog` with strict monospace filtering for code fonts, coupled with unfocused privacy obfuscation using `Redacted Script` scribbles.
* **Documentation**: See [`docs/user-guide.md`](user-guide.md#3-typography-customization).

### 6.4 Local Full-Text Search & Interactive Popover
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Implemented hybrid in-memory and disk full-text search engine (`Jots.SearchService`) and interactive desktop popover (`Jots.SearchPopover`) with relevance scoring, snippet extraction, and keyboard navigation (`Ctrl + F` / `Ctrl + Shift + F`).
* **Documentation**: See [`docs/user-guide.md`](user-guide.md#searching-notes).

### 6.5 Daily Routine Adoption & Presence
* **Status**: ✅ **Completed**
* **Summary**: Delivered packaging-aware launch guidance for disconnected MCP requests and explicit autostart control with runtime-aware command resolution. `jots-mcp` now returns actionable launch commands based on runtime packaging context (Flatpak/AppImage/Native).
* **Documentation**: See [`docs/development/mcp-server.md`](development/mcp-server.md#5-application-disconnected-handling) and [`docs/user-guide.md`](user-guide.md#5-preferences-and-customization).

### 6.6 Automated Git Backup and Remote Synchronization
* **Status**: ✅ **Completed** (v1.3.0)
* **Summary**: Integrated non-blocking background Git backup and remote synchronization service (`Jots.GitSyncService`). Features include debounced auto-commits on note edit/deletion, configurable periodic push intervals, on-demand "Sync now" trigger, remote reachability connectivity tests, automatic allowlist-based `.gitignore` policy enforcement, and asynchronous `GLib.Subprocess` execution without UI thread blocking.
* **Documentation**: See [`docs/architecture.md`](architecture.md#35-backup-remote-state-matrix-gitsyncservice) and [`docs/user-guide.md`](user-guide.md#5-preferences-and-customization).

### 6.7 Focus-Aware Minimalist Desktop Chrome
* **Status**: ✅ **Completed** (v1.3.0)
* **Summary**: Added dynamic focus-aware auto-hiding for sticky note toolbars via `Jots.ChromeController`. Unfocused notes smoothly hide their bottom action bar to present a pure post-it note aesthetic while keeping note titles visible. Hovering over unfocused notes triggers a 250ms debounced reveal to prevent mouse-sweep flicker, and active popovers lock the toolbar in view.
* **Documentation**: See [`docs/use-cases/50-theming-appearance.md`](use-cases/50-theming-appearance.md#5030-focus-aware-minimalist-desktop-chrome) and [`docs/user-guide.md`](user-guide.md#6-preferences-privacy--note-protection).

### 6.8 Retire List Item Prefix Preference
* **Status**: ✅ **Completed** (v1.4.0)
* **Summary**: Removed the configurable list item prefix (Preferences dropdown, `list-prefix` GSettings key, `Jots.ListPrefix` enum, and the unused `Jots.TextBuffer` class it backed). Unordered list markers (`-`, `*`, `+`) remain parsed and rendered as equivalent via `MarkdownBuffer`, marker-agnostic, with no migration needed for existing notes.
* **Documentation**: See [`docs/use-cases/30-text-editing.md`](use-cases/30-text-editing.md).
