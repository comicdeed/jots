# Product Roadmap and Feature Candidates

A curated backlog of architectural enhancements, capabilities, and feature candidates graded against the [Idea Evaluation and Grading Framework](development/ideas-grading.md).

---

## Table of Contents

- [Product Roadmap and Feature Candidates](#product-roadmap-and-feature-candidates)
  - [Table of Contents](#table-of-contents)
  - [1. Evaluation Summary \& Score Matrix](#1-evaluation-summary--score-matrix)
  - [2. High-Priority Initiatives (Tier 1)](#2-high-priority-initiatives-tier-1)
    - [2.1 Note Organizer and Management Interface](#21-note-organizer-and-management-interface)
    - [2.2 Free-Form In-Text Tagging with Autocompletion](#22-free-form-in-text-tagging-with-autocompletion)
    - [2.3 Automated Git Backup and Remote Synchronization](#23-automated-git-backup-and-remote-synchronization)
  - [3. Planned Backlog (Tier 2)](#3-planned-backlog-tier-2)
    - [3.1 Daily Routine Adoption \& Presence (Moved to Completed Initiatives)](#31-daily-routine-adoption--presence-moved-to-completed-initiatives)
    - [3.2 Bidirectional Note Linking (`[[Note Title]]`)](#32-bidirectional-note-linking-note-title)
    - [3.3 Note Archiving and Trash Bin Lifecycle](#33-note-archiving-and-trash-bin-lifecycle)
    - [3.4 AppImage Update Information Embedding](#34-appimage-update-information-embedding)
    - [3.5 AppImage Provenance and Signature Verification](#35-appimage-provenance-and-signature-verification)
    - [3.6 Retire List Item Prefix Preference](#36-retire-list-item-prefix-preference)
  - [4. Deferred / Incubating Concepts (Tier 4)](#4-deferred--incubating-concepts-tier-4)
    - [4.1 Google Keep Backend Synchronization](#41-google-keep-backend-synchronization)
  - [5. Completed Initiatives](#5-completed-initiatives)
    - [5.1 Native Model Context Protocol (MCP) Server](#51-native-model-context-protocol-mcp-server)
    - [5.2 Markdown Storage with YAML Front Matter \& Live Rendering](#52-markdown-storage-with-yaml-front-matter--live-rendering)
    - [5.3 Typography Customization \& Obfuscated Scribbly Mode](#53-typography-customization--obfuscated-scribbly-mode)
    - [5.4 Local Full-Text Search \& Interactive Popover](#54-local-full-text-search--interactive-popover)
    - [5.5 Daily Routine Adoption \& Presence](#55-daily-routine-adoption--presence)

---

## 1. Evaluation Summary & Score Matrix

The score matrix is curated to include only non-completed roadmap candidates (active, planned, deferred, or incubating). Once an initiative ships, remove it from this matrix and keep its historical record in [Section 5: Completed Initiatives](#5-completed-initiatives).

| Feature Concept | Impact (40%) | Alignment (35%) | Feasibility (25%) | Composite Score | Tier / Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Note Organizer & Management Interface** | 4.4 | 4.6 | 4.2 | **4.42** | 🟢 Tier 1 (Active Priority) |
| **Automated Git Backup & Remote Sync** | 4.5 | 4.6 | 4.0 | **4.41** | 🟢 Tier 1 (Active Priority) |
| **Free-Form In-Text Tagging (`#tag`)** | 4.0 | 4.0 | 3.8 | **3.95** | 🟢 Tier 1 (Active Priority) |
| **Bidirectional Note Linking (`[[Note]]`)** | 3.8 | 3.6 | 3.4 | **3.63** | 🟡 Tier 2 (Planned Backlog) |
| **Note Archiving & Trash Lifecycle** | 3.4 | 3.8 | 4.2 | **3.74** | 🟡 Tier 2 (Planned Backlog) |
| **Retire List Item Prefix Preference** | 3.4 | 4.5 | 4.6 | **4.09** | 🟡 Tier 2 (Planned Backlog) |
| **AppImage Update Info Embedding** | 3.0 | 4.2 | 4.5 | **3.72** | 🟡 Tier 2 (Planned Backlog) |
| **AppImage Provenance & Signatures** | 3.2 | 4.4 | 4.0 | **3.92** | 🟡 Tier 2 (Planned Backlog) |
| **Google Keep Backend Sync** | 3.0 | 1.8 | 1.2 | **2.13** | 🔴 Tier 4 (Deferred) |

---

## 2. High-Priority Initiatives (Tier 1)

### 2.1 Note Organizer and Management Interface
* **Score**: `4.42` (Tier 1: Active Priority)
* **Goal**: Provide an optional central manager interface (`Jots.LibraryWindow`) to organize, filter, hide/close, and restore notes without cluttering the desktop canvas.
* **Implementation Strategy**:
  * **Active vs. Stored / Hidden Lifecycle**: Distinguish between "Pinned to Desktop" (active floating windows) and "Stored in Library" (persisted `.md` files hidden from desktop view).
  * **Tag Filtering & Categories**: Display aggregated `#tag` pills and category filters directly in the library view.
  * **Card Grid & List View**: Visual note cards with theme color accents, titles, modification dates, and search snippets.
  * **Trash & Recovery**: Integrate soft-deletion and safe restoration.

### 2.2 Free-Form In-Text Tagging with Autocompletion
* **Score**: `3.95` (Tier 1: Active Priority)
* **Goal**: Allow free-form `#tag` definitions anywhere in note bodies with dynamic tag indexing, autocompletion popups, and sidebar filter synergy.
* **Implementation Strategy**:
  * Leverage `GtkTextTag` in `MarkdownBuffer` (`TAG_TAG`) for subtle pastel highlight badge styling.
  * Index active tags in memory via `NoteManager` to power autocompletion and category filters in the Note Organizer.

### 2.3 Automated Git Backup and Remote Synchronization
* **Score**: `4.41` (Tier 1: Active Priority)
* **Goal**: Prevent catastrophic data loss, maintain an immutable local change history, and enable seamless multi-device backup by synchronizing the Markdown storage repository (`~/.local/share/<app_id>/notes/`) with a user-specified Git remote.
* **Implementation Strategy**:
  * **Preferences Configuration**:
    * Add a dedicated **Backup & Synchronization** group in the Preferences window.
    * Allow configuring a Git remote repository URL (SSH or HTTPS) or auto-detect an existing upstream remote if the notes directory is already initialized as a Git repository.
    * Provide a periodic backup cadence selector (e.g. Disabled, Every 5 min, 15 min, 30 min, Hourly).
  * **Hybrid Commit & Push Trigger Mechanics**:
    * **Debounced Save Commit**: Hook into `Storage.save_note()` / `Storage.delete_note()` (or directory file monitors) to create debounced, automatic Git commits upon editing with clean, descriptive commit messages (e.g., `backup: update note <title-or-id>`).
    * **Periodic Remote Push**: A background non-blocking timer pushes queued commits to the remote at the configured sync interval.
    * **Immediate Sync on Demand & Clean Exit**: Provide a manual "Sync Now" trigger in preferences/menu and perform an automatic non-blocking flush and push on application shutdown.
  * **Non-Blocking Execution & Offline Resilience**:
    * Execute all Git operations asynchronously via `GLib.Subprocess` (or `libgit2-glib`) to eliminate any UI blocking, latency, or hangs on slow/flaky connections.
    * Seamlessly queue commits locally while offline; automatically resume pushing once network connectivity is restored without surfacing blocking modal dialogs.
  * **Repository Initialization & Strict Allowlist `.gitignore` Policy**:
    * Transparently initialize `git init` on first enable if not already present.
    * **Startup `.gitignore` Evaluation**: On startup (and initialization), evaluate and ensure a strict allowlist-based `.gitignore` is present.
    * **Allowlist Default (`*` with `!*.md`)**: Ignore everything by default (`*`), un-ignoring only `.gitignore`, directories (`!*/`), and Markdown notes (`!*.md`). This guards against committing stray editor swap files (`*.swp`, `*~`, `.#*`), OS metadata (`.DS_Store`), temporary backups, or newly introduced internal app files, while leaving a clean path to expand allowed extensions in the future.

---

## 3. Planned Backlog (Tier 2)

### 3.1 Daily Routine Adoption & Presence (Moved to Completed Initiatives)
* **Status**: Moved to [Section 5.5: Daily Routine Adoption & Presence](#55-daily-routine-adoption--presence).
* **Note**: The remaining manual-quit suppression/cooldown hardening is tracked as feedback-driven follow-up work and is intentionally deferred until a real user issue is reported.

### 3.2 Bidirectional Note Linking (`[[Note Title]]`)
* **Score**: `3.63` (Tier 2: Planned Backlog)
* **Goal**: Inter-note navigation using wiki-style `[[Note Title]]` links that open or focus target sticky notes on click.
* **Implementation Strategy**:
  * Recognize `[[...]]` patterns in `MarkdownBuffer` and render as clickable note links.
  * Resolve target note by UUID or Title in `NoteManager`.

### 3.3 Note Archiving and Trash Bin Lifecycle
* **Score**: `3.74` (Tier 2: Planned Backlog)
* **Goal**: Provide a lightweight trash/archive directory instead of immediate file deletion, allowing easy recovery of accidentally discarded notes.

### 3.4 AppImage Update Information Embedding
* **Score**: `3.72` (Tier 2: Planned Backlog)
* **Goal**: Embed [AppImage update information](https://github.com/AppImage/AppImageSpec/blob/master/draft.md#update-information) into released AppImage binaries so that tools such as `AppImageUpdate` and `appimageupdatetool` can perform efficient delta auto-updates without requiring users to re-download the full binary.
* **Background**: The [AppImage Type 2 spec](https://github.com/AppImage/AppImageSpec/blob/master/draft.md#type-2-image-format) defines an optional `.upd-info` ELF section (a 512-byte field inside the runtime). When populated, it describes the transport mechanism and location of a `.zsync` control file. The `zsync` algorithm downloads only the changed binary blocks, making incremental upgrades fast even over metered connections.
* **Implementation Strategy**:
  * **Transport string**: Use the `gh-releases-zsync` format to point at the GitHub Releases page:
    ```
    gh-releases-zsync|comicdeed|jots|latest|Jots-*-x86_64.AppImage.zsync
    ```
  * **Build-time injection**: Pass the `-u` flag to `appimagetool` during `packaging/appimage/build-appimage.sh` so the string is written into the `.upd-info` section of each produced AppImage.
  * **CI artifact generation**: Extend `.github/workflows/release.yml` to run `zsyncmake` on the packaged `x86_64` and `aarch64` AppImages, producing a matching `.zsync` sidecar file per architecture, and upload both artifacts to the GitHub Release.
  * **Packaging guardrail**: Assert in `build-appimage.sh` that the `.upd-info` section is non-empty after build (e.g., `readelf -S Jots.AppImage | grep upd_info`) to prevent silent regressions.
  * **Architecture parity (Docker / CI)**: Per the zero-dependency-drift rule, add `zsync` / `zsyncmake` to both `packaging/appimage/Dockerfile` and the runner `apt` install step in `CI.yml` / `release.yml` simultaneously.

### 3.5 AppImage Provenance and Signature Verification
* **Score**: `3.92` (Tier 2: Planned Backlog)
* **Goal**: Improve release trust and provenance by cryptographically signing shipped AppImages and publishing verification material, following the AppImage signature guidance: [Embedding a signature in an AppImage](https://docs.appimage.org/packaging-guide/optional/signatures.html).
* **Background**: Unsigned binaries require users to trust the distribution channel alone. Embedded signatures and public verification keys allow users, downstream packagers, and automated pipelines to validate artifact origin and integrity after download.
* **Implementation Strategy**:
  * **Release key management**: Create a dedicated Jots release-signing GPG key, store private key material as encrypted CI secrets, and publish the armored public key in the repository and release assets.
  * **Build-time signing**: Enable AppImage signing in `packaging/appimage/build-appimage.sh` for both `x86_64` and `aarch64` outputs so each produced artifact contains an embedded signature section.
  * **Verification artifacts**: Attach the public key and a concise `VERIFY.md` snippet to each GitHub Release, including exact commands to validate signatures with AppImage tooling and GPG.
  * **CI provenance checks**: Add a post-build verification stage in `.github/workflows/release.yml` that fails the release if signature extraction or signature verification fails for any architecture.
  * **Operational hardening**: Define key rotation cadence, revocation certificate storage, and incident response steps for compromised signing keys in `docs/development/release-workflow.md`.

### 3.6 Retire List Item Prefix Preference
* **Score**: `4.09` (Tier 2: Planned Backlog)
* **Goal**: Reduce preference-surface complexity by removing the list item prefix selector and standardizing newly inserted Markdown unordered list markers.
* **Background**: Markdown unordered list markers (`-`, `*`, `+`) are semantically equivalent for parsing and rendering. With Markdown-native storage now canonical, prefix selection is mostly a style choice and no longer a core functional setting.
* **Implementation Strategy**:
  * **Standardized insertion marker**: Use a single default marker for newly inserted list items (recommended: `-`) while preserving support for existing notes containing `*` or `+`.
  * **Preferences simplification**: Remove the list prefix control from Preferences and associated user-facing explanatory copy.
  * **Compatibility-first parsing**: Keep list detection and rendering behavior marker-agnostic so historical notes remain unchanged and require no migration.
  * **Config cleanup**: Remove the `list-prefix` GSettings key and related constants only after behavior and test updates are complete.
  * **Test and docs alignment**: Update use-case references, unit tests, and user guide sections to reflect one insertion default and multi-marker compatibility.
* **Acceptance Criteria**:
  * Existing notes using `-`, `*`, or `+` still render and behave correctly.
  * Pressing Enter on unordered list items continues with the standardized default marker.
  * Preferences no longer expose list prefix configuration.
  * No data migration is required.

---

## 4. Deferred / Incubating Concepts (Tier 4)

### 4.1 Google Keep Backend Synchronization
* **Score**: `2.13` (Tier 4: Deferred)
* **Rationale**: While an official [Google Keep REST API](https://developers.google.com/workspace/keep/api/reference/rest) exists, Google restricts it strictly to **Google Workspace Enterprise domains** with domain-wide delegation for security auditing/CASB. It is unavailable for standard personal (consumer) `@gmail.com` Google accounts. Supporting personal accounts would require reverse-engineered web-scraping libraries (such as `gkeepapi`), which frequently break on authentication and 2FA changes. Introducing cloud synchronization dependencies also compromises Jots' core mission of robust, offline-first local simplicity.

---

## 5. Completed Initiatives

### 5.1 Native Model Context Protocol (MCP) Server
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Implemented standalone native Vala `jots-mcp` executable (`src/Mcp/`) and D-Bus IPC service (`io.github.comicdeed.jots.Notes`), providing line-delimited JSON-RPC 2.0 stdio communication for AI assistants (Claude Desktop, Cursor, Antigravity, Gemini CLI) with zero external Python dependencies.
* **Documentation**: See [`docs/development/mcp-server.md`](development/mcp-server.md) and [`docs/user-guide.md`](user-guide.md#6-ai-assistant--mcp-integration).

### 5.2 Markdown Storage with YAML Front Matter & Live Rendering
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Replaced monolithic JSON storage with human-readable `.md` files containing YAML front-matter headers. Implemented live native `MarkdownBuffer` supporting real-time syntax highlighting for headings (`#`, `##`, `###`), bold/italic formatting, checklists (`- [ ]`, `- [x]`), blockquotes (`>`), code spans, code fences, and clickable links.
* **Documentation**: See [`docs/architecture.md`](architecture.md#32-markdown-storage-and-serialization) and [`docs/user-guide.md`](user-guide.md#4-markdown-formatting--live-rendering).

### 5.3 Typography Customization & Obfuscated Scribbly Mode
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Added global font family and font size preferences via `Gtk.FontDialog` with strict monospace filtering for code fonts, coupled with unfocused privacy obfuscation using `Redacted Script` scribbles.
* **Documentation**: See [`docs/user-guide.md`](user-guide.md#3-typography-customization).

### 5.4 Local Full-Text Search & Interactive Popover
* **Status**: ✅ **Completed** (v1.0.0)
* **Summary**: Implemented hybrid in-memory and disk full-text search engine (`Jots.SearchService`) and interactive desktop popover (`Jots.SearchPopover`) with relevance scoring, snippet extraction, and keyboard navigation (`Ctrl + F` / `Ctrl + Shift + F`).
* **Documentation**: See [`docs/user-guide.md`](user-guide.md#searching-notes).

### 5.5 Daily Routine Adoption & Presence
* **Status**: ✅ **Completed**
* **Summary**: Delivered packaging-aware launch guidance for disconnected MCP requests and explicit autostart control with runtime-aware command resolution. `jots-mcp` now returns actionable launch commands based on runtime packaging context (Flatpak/AppImage/Native), enabling assistant-driven recovery by launching the app and retrying. Autostart controls are synchronized to on-disk registration state to keep user intent and actual startup behavior aligned.
* **Deferred hardening (intentional)**: Manual-quit suppression/cooldown behavior remains deferred and will be implemented only if validated user feedback indicates relaunch-loop friction.
* **Documentation**: See [`docs/development/mcp-server.md`](development/mcp-server.md#5-application-disconnected-handling), [`docs/user-guide.md`](user-guide.md#5-preferences-and-customization), and [`docs/user-guide.md`](user-guide.md#6-ai-assistant--mcp-integration).
