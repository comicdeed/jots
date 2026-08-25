# Product Roadmap and Feature Candidates

A curated backlog of architectural enhancements, capabilities, and feature candidates graded against the [Idea Evaluation and Grading Framework](development/ideas-grading.md).

---

## Table of Contents

* [1. Evaluation Summary & Score Matrix](#1-evaluation-summary--score-matrix)
* [2. High-Priority Initiatives (Tier 1)](#2-high-priority-initiatives-tier-1)
  * [2.1 Local Full-Text Search and Note Indexing](#21-local-full-text-search-and-note-indexing)
  * [2.2 Free-Form In-Text Tagging with Autocompletion](#22-free-form-in-text-tagging-with-autocompletion)
* [3. Planned Backlog (Tier 2)](#3-planned-backlog-tier-2)
  * [3.1 Bidirectional Note Linking (`[[Note Title]]`)](#31-bidirectional-note-linking-note-title)
  * [3.2 Note Archiving and Trash Bin Lifecycle](#32-note-archiving-and-trash-bin-lifecycle)
* [4. Deferred / Incubating Concepts (Tier 4)](#4-deferred--incubating-concepts-tier-4)
  * [4.1 Google Keep Backend Synchronization](#41-google-keep-backend-synchronization)
* [5. Completed Initiatives](#5-completed-initiatives)
  * [5.1 Native Model Context Protocol (MCP) Server](#51-native-model-context-protocol-mcp-server)
  * [5.2 Markdown Storage with YAML Front Matter & Live Rendering](#52-markdown-storage-with-yaml-front-matter--live-rendering)
  * [5.3 Typography Customization & Obfuscated Scribbly Mode](#53-typography-customization--obfuscated-scribbly-mode)

---

## 1. Evaluation Summary & Score Matrix

| Feature Concept | Impact (40%) | Alignment (35%) | Feasibility (25%) | Composite Score | Tier / Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Native MCP Server (`jots-mcp`)** | 5.0 | 4.5 | 4.5 | **4.70** | ✅ **Completed** (v4.3.0) |
| **Markdown Storage & Live Rendering** | 4.6 | 5.0 | 4.4 | **4.69** | ✅ **Completed** (v4.3.0) |
| **Typography & Scribbly Obfuscation** | 4.2 | 4.5 | 4.5 | **4.38** | ✅ **Completed** (v4.3.0) |
| **Local Note Indexing & Search** | 4.2 | 4.4 | 4.0 | **4.22** | ✅ **Completed** (v4.4.0) |
| **Free-Form In-Text Tagging (`#tag`)** | 4.0 | 4.0 | 3.8 | **3.95** | 🟢 Tier 1 (Active Priority) |
| **Bidirectional Note Linking (`[[Note]]`)** | 3.8 | 3.6 | 3.4 | **3.63** | 🟡 Tier 2 (Planned Backlog) |
| **Note Archiving & Trash Lifecycle** | 3.4 | 3.8 | 4.2 | **3.74** | 🟡 Tier 2 (Planned Backlog) |
| **Google Keep Backend Sync** | 3.0 | 1.8 | 1.2 | **2.13** | 🔴 Tier 4 (Deferred) |

---

## 2. High-Priority Initiatives (Tier 1)

### 2.1 Local Full-Text Search and Note Indexing
* **Score**: `4.22` (Tier 1: Active Priority)
* **Goal**: Fast, lightweight global search across all stored markdown notes via keyboard shortcut (`Ctrl + Shift + F` or desktop quick search).
* **Implementation Strategy**:
  * Leverages discrete `.md` files for instant ripgrep / SQLite FTS5 querying.
  * Presents an unobtrusive Granite popover search list jumping directly to matching notes or opening inactive notes.

### 2.2 Free-Form In-Text Tagging with Autocompletion
* **Score**: `3.95` (Tier 1: Active Priority)
* **Goal**: Allow free-form `#tag` definitions anywhere in note bodies with dynamic tag indexing and autocompletion popups.
* **Implementation Strategy**:
  * Leverage `GtkTextTag` in `MarkdownBuffer` for subtle highlight styling without breaking plain text flow.
  * Index active tags in memory to power tag filtering across open windows and search popovers.

---

## 3. Planned Backlog (Tier 2)

### 3.1 Bidirectional Note Linking (`[[Note Title]]`)
* **Score**: `3.63` (Tier 2: Planned Backlog)
* **Goal**: Inter-note navigation using wiki-style `[[Note Title]]` links that open or focus target sticky notes on click.
* **Implementation Strategy**:
  * Recognize `[[...]]` patterns in `MarkdownBuffer` and render as clickable note links.
  * Resolve target note by UUID or Title in `NoteManager`.

### 3.2 Note Archiving and Trash Bin Lifecycle
* **Score**: `3.74` (Tier 2: Planned Backlog)
* **Goal**: Provide a lightweight trash/archive directory instead of immediate file deletion, allowing easy recovery of accidentally discarded notes.

---

## 4. Deferred / Incubating Concepts (Tier 4)

### 4.1 Google Keep Backend Synchronization
* **Score**: `2.13` (Tier 4: Deferred)
* **Rationale**: While an official [Google Keep REST API](https://developers.google.com/workspace/keep/api/reference/rest) exists, Google restricts it strictly to **Google Workspace Enterprise domains** with domain-wide delegation for security auditing/CASB. It is unavailable for standard personal (consumer) `@gmail.com` Google accounts. Supporting personal accounts would require reverse-engineered web-scraping libraries (such as `gkeepapi`), which frequently break on authentication and 2FA changes. Introducing cloud synchronization dependencies also compromises Jots' core mission of robust, offline-first local simplicity.

---

## 5. Completed Initiatives

### 5.1 Native Model Context Protocol (MCP) Server
* **Status**: ✅ **Shipped** (v4.3.0)
* **Summary**: Implemented standalone native Vala `jots-mcp` executable (`src/Mcp/`) and D-Bus IPC service (`io.github.comicdeed.jots.Notes`), providing line-delimited JSON-RPC 2.0 stdio communication for AI assistants (Claude Desktop, Cursor, Antigravity, Gemini CLI) with zero external Python dependencies.
* **Documentation**: See [`docs/development/mcp-server.md`](development/mcp-server.md) and [`docs/user-guide.md`](user-guide.md#6-ai-assistant--mcp-integration).

### 5.2 Markdown Storage with YAML Front Matter & Live Rendering
* **Status**: ✅ **Shipped** (v4.3.0)
* **Summary**: Replaced monolithic JSON storage with human-readable `.md` files containing YAML front-matter headers. Implemented live native `MarkdownBuffer` supporting real-time syntax highlighting for headings (`#`, `##`, `###`), bold/italic formatting, checklists (`- [ ]`, `- [x]`), blockquotes (`>`), code spans, code fences, and clickable links.
* **Documentation**: See [`docs/architecture.md`](architecture.md#32-markdown-storage-and-serialization) and [`docs/user-guide.md`](user-guide.md#4-markdown-formatting--live-rendering).

### 5.3 Typography Customization & Obfuscated Scribbly Mode
* **Status**: ✅ **Shipped** (v4.3.0)
* **Summary**: Added global font family and font size preferences via `Gtk.FontDialog` with strict monospace filtering for code fonts, coupled with unfocused privacy obfuscation using `Redacted Script` scribbles.
* **Documentation**: See [`docs/user-guide.md`](user-guide.md#3-typography-customization).
