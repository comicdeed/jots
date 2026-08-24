# Product Roadmap and Feature Candidates

A curated backlog of architectural enhancements, capabilities, and feature candidates graded against the [Idea Evaluation and Grading Framework](development/ideas-grading.md).

---

## Table of Contents

* [1. Evaluation Summary & Score Matrix](#1-evaluation-summary--score-matrix)
* [2. High-Priority Initiatives (Tier 1)](#2-high-priority-initiatives-tier-1)
  * [2.1 Local MCP Server for AI Agent Integration](#21-local-mcp-server-for-ai-agent-integration)
  * [2.2 Markdown Storage with YAML Front Matter](#22-markdown-storage-with-yaml-front-matter)
* [3. Planned Backlog (Tier 2)](#3-planned-backlog-tier-2)
  * [3.1 Free-Form In-Text Tagging with Autocompletion](#31-free-form-in-text-tagging-with-autocompletion)
  * [3.2 Local Full-Text Search and Note Indexing](#32-local-full-text-search-and-note-indexing)
* [4. Deferred / Incubating Concepts (Tier 4)](#4-deferred--incubating-concepts-tier-4)
  * [4.1 Google Keep Backend Synchronization](#41-google-keep-backend-synchronization)

---

## 1. Evaluation Summary & Score Matrix

| Feature Concept | Impact (40%) | Alignment (35%) | Feasibility (25%) | Composite Score | Tier |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Local MCP Server for AI Agents** | 5.0 | 4.5 | 3.5 | **4.45** | 🟢 Tier 1 |
| **Markdown + Front Matter Storage** | 4.2 | 5.0 | 4.0 | **4.43** | 🟢 Tier 1 |
| **Free-Form In-Text Tagging (`#tag`)** | 4.0 | 4.0 | 3.5 | **3.88** | 🟡 Tier 2 |
| **Local Note Indexing & Search** | 3.8 | 4.2 | 3.6 | **3.89** | 🟡 Tier 2 |
| **Google Keep Backend Sync** | 3.0 | 1.8 | 1.2 | **2.13** | 🔴 Tier 4 |

---

## 2. High-Priority Initiatives (Tier 1)

### 2.1 Local MCP Server for AI Agent Integration
* **Score**: `4.45` (Tier 1: Active Priority - Implemented on `feat/mcp-server`)
* **Goal**: Provide a native local **Model Context Protocol (MCP)** server enabling AI tools (Claude Desktop, Cursor, Gemini CLI, local agents) to query, create, edit, search, and delete sticky notes via standard JSON-RPC over `stdio`.
* **Key Capabilities**:
  * Tools: `list_notes`, `read_note`, `create_note`, `update_note`, `delete_note`, `search_notes`.
  * Real-time sync: Direct D-Bus session IPC (`io.github.comicdeed.jots.McpService`) ensuring notes appear and update instantly on the desktop.
  * Defensive guardrails: 10 KB content limit, 120 char title limit, 50 active note ceiling.
* **Architectural Advantage**: Zero UI clutter for manual note-takers; transformative utility for developers and AI pair-programmers.

### 2.2 Markdown Storage with YAML Front Matter
* **Score**: `4.43` (Tier 1: Active Priority)
* **Goal**: Transition from the monolithic `saved_state.json` to individual human-readable `.md` files stored under `~/.local/share/io.github.comicdeed.jots/notes/`.
* **Format**:
  ```markdown
  ---
  id: "550e8400-e29b-41d4-a716-446655440000"
  title: "Meeting Action Items"
  theme: "blueberry"
  zoom: 100
  x: 240
  y: 180
  width: 320
  height: 280
  collapsed: false
  created_at: 2026-08-24T18:00:00Z
  modified_at: 2026-08-24T18:05:00Z
  ---
  - [x] Complete icon rasterization
  - [ ] Finalize roadmap document
  ```
* **Key Advantages**: Native interoperability with Obsidian/Logseq, transparent git versioning, effortless backup scripts, and simplified file watching.

---

## 3. Planned Backlog (Tier 2)

### 3.1 Free-Form In-Text Tagging with Autocompletion
* **Score**: `3.88` (Tier 2: Planned Backlog)
* **Goal**: Allow free-form `#tag` definitions anywhere in the note body with dynamic tag indexing and autocompletion popups.
* **Implementation Strategy**:
  * Leverage `GtkTextTag` for subtle highlight styling without breaking plain text flow.
  * Index active tags in memory to power tag filtering across open windows.

### 3.2 Local Full-Text Search and Note Indexing
* **Score**: `3.89` (Tier 2: Planned Backlog)
* **Goal**: Fast, lightweight global search across all stored notes via keyboard shortcut (`Ctrl + Shift + F` or desktop quick search).
* **Implementation Strategy**:
  * Pairs directly with Markdown storage for instant ripgrep / SQLite FTS5 querying.
  * Presents an unobtrusive Granite popover search list jumping directly to matching notes.

---

## 4. Deferred / Incubating Concepts (Tier 4)

### 4.1 Google Keep Backend Synchronization
* **Score**: `2.13` (Tier 4: Deferred)
* **Rationale**: While an official [Google Keep REST API](https://developers.google.com/workspace/keep/api/reference/rest) exists, Google restricts it strictly to **Google Workspace Enterprise domains** with domain-wide delegation for security auditing/CASB. It is unavailable for standard personal (consumer) `@gmail.com` Google accounts. Supporting personal accounts would require reverse-engineered web-scraping libraries (such as `gkeepapi`), which frequently break on authentication and 2FA changes. Introducing cloud synchronization dependencies also compromises Jots' core mission of robust, offline-first local simplicity.
