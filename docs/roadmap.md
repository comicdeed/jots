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
  - [3. Planned Backlog (Tier 2)](#3-planned-backlog-tier-2)
    - [3.1 Daily Routine Adoption \& Presence](#31-daily-routine-adoption--presence)
    - [3.2 Bidirectional Note Linking (`[[Note Title]]`)](#32-bidirectional-note-linking-note-title)
    - [3.3 Note Archiving and Trash Bin Lifecycle](#33-note-archiving-and-trash-bin-lifecycle)
    - [3.4 AppImage Update Information Embedding](#34-appimage-update-information-embedding)
    - [3.5 AppImage Provenance and Signature Verification](#35-appimage-provenance-and-signature-verification)
  - [4. Deferred / Incubating Concepts (Tier 4)](#4-deferred--incubating-concepts-tier-4)
    - [4.1 Google Keep Backend Synchronization](#41-google-keep-backend-synchronization)
  - [5. Completed Initiatives](#5-completed-initiatives)
    - [5.1 Native Model Context Protocol (MCP) Server](#51-native-model-context-protocol-mcp-server)
    - [5.2 Markdown Storage with YAML Front Matter \& Live Rendering](#52-markdown-storage-with-yaml-front-matter--live-rendering)
    - [5.3 Typography Customization \& Obfuscated Scribbly Mode](#53-typography-customization--obfuscated-scribbly-mode)
    - [5.4 Local Full-Text Search \& Interactive Popover](#54-local-full-text-search--interactive-popover)

---

## 1. Evaluation Summary & Score Matrix

The score matrix is curated to include only non-completed roadmap candidates (active, planned, deferred, or incubating). Once an initiative ships, remove it from this matrix and keep its historical record in [Section 5: Completed Initiatives](#5-completed-initiatives).

| Feature Concept | Impact (40%) | Alignment (35%) | Feasibility (25%) | Composite Score | Tier / Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Note Organizer & Management Interface** | 4.4 | 4.6 | 4.2 | **4.42** | 🟢 Tier 1 (Active Priority) |
| **Free-Form In-Text Tagging (`#tag`)** | 4.0 | 4.0 | 3.8 | **3.95** | 🟢 Tier 1 (Active Priority) |
| **Daily Routine Adoption & Presence** | 4.1 | 4.4 | 4.3 | **4.26** | 🟡 Tier 2 (Planned Backlog) |
| **Bidirectional Note Linking (`[[Note]]`)** | 3.8 | 3.6 | 3.4 | **3.63** | 🟡 Tier 2 (Planned Backlog) |
| **Note Archiving & Trash Lifecycle** | 3.4 | 3.8 | 4.2 | **3.74** | 🟡 Tier 2 (Planned Backlog) |
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

---

## 3. Planned Backlog (Tier 2)

### 3.1 Daily Routine Adoption & Presence
* **Score**: `4.26` (Tier 2: Planned Backlog)
* **Goal**: Increase daily active usage by ensuring Jots appears at the right time with minimal user friction, while preserving explicit user control.
* **Implementation Strategy**:
  * **Dual Startup Modes (User Choice)**: Support two explicit modes: (a) "Launch Jots on login" (desktop autostart) and (b) "Launch Jots only when MCP needs it" (no login autostart), so assistant-first users can avoid startup clutter.
  * **First MCP Invocation Guided Enablement**: When `jots-mcp` receives an operation and the GUI app is not running, offer one-time guided setup for either startup mode instead of defaulting directly to login autostart.
  * **Mid-Session Quit Policy**: If the user intentionally quits Jots during a session, treat it as temporary suppression and avoid immediate forced relaunch loops; only relaunch on the next explicit MCP action that requires UI-backed operations.
  * **Distro-Aware Launch Resolution**: Add a startup resolver in `jots-mcp` that detects available launch paths in priority order (active D-Bus name activation, desktop ID via `gio launch`, Flatpak ID invocation, then direct binary fallback) to handle distro/package differences predictably.
  * **Capability Probing and Telemetry-Free Fallback**: Perform local capability checks before launch attempts, store the successful method locally for future invocations, and surface actionable local errors when no method works.
  * **Safety and Predictability Constraints**: Keep behavior explicit and reversible, including visible toggle state, one-time prompt suppression, user-overridable cooldown after manual quit, and no repeated background auto-enables without consent.
  * **Cross-Context Documentation**: Update `docs/user-guide.md` and MCP setup docs to explain when autostart is recommended, how to enable/disable it, and expected behavior in both desktop and assistant-first usage.

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
