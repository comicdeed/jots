---
name: user-guide-review
description: Use when reviewing, updating, or authoring end-user documentation (such as docs/user-guide.md). Calibrates voice, tone, and scope for everyday desktop Linux users comfortable with Markdown and basic Git, ensuring internal engineering mechanics and jargon are moved to developer documentation.
---

# End-User Documentation Review & Authoring Skill

This skill defines the editorial standards, reader calibration rules, content boundary guidelines, and quality gates for authoring and reviewing end-user documentation in **Jots** (primarily [`docs/user-guide.md`](../../../docs/user-guide.md)).

---

## 🎯 Essential Reader Attributes

When authoring or reviewing user documentation, calibrate the content to a reader with the following attributes:

1. **Desktop Native**: Uses a Linux desktop environment (such as GNOME, KDE Plasma, XFCE, cosmic, or elementary OS) and expects standard graphical window management, keyboard shortcuts, tray/menu behaviors, and system themes.
2. **Text & Markdown Proficient**: Comfortable writing in Markdown syntax (`# headers`, `**bold**`, `- [ ] checklists`, `` `code` ``), and expects notes to stay clean, readable, and portable.
3. **Familiar with Basic Git Concepts**: Understands remote repository URLs (HTTPS/SSH) and basic versioning terms (commit, push, sync, conflict/divergence) for personal backups, but does not need explanations of internal merge drivers or commit plumbing.
4. **Non-Developer**: Does **not** read application source code, does not inspect AST/parser pipelines or widget classes, does not manage D-Bus session interfaces, and does not debug application lifecycles.
5. **Outcome-Focused**: Reads documentation to accomplish concrete desktop tasks (taking notes, organizing lists, customizing colors, enabling sync, connecting an AI assistant) quickly and without cognitive clutter.

---

## 🧭 Content Boundary & Scope Rules

### What to Include in User Documentation
* **Discrete User Actions**: How to create, edit, search, organize, lock, delete, and restore notes.
* **Complete Shortcut Reference**: Comprehensive table of keyboard shortcuts and mouse gestures with plain-language action descriptions.
* **Live Markdown Behavior**: Clear table showing syntax input alongside live rendered appearance.
* **UI Features & Preferences**: Color themes, typography configuration, focus-aware toolbar auto-hide, Scribbly privacy mode, and autostart.
* **Practical Backup & Sync**: Step-by-step setup for remote Git backups, automatic sync schedules, and plain-language status explanations.
* **Straightforward AI Client Setup**: Ready-to-use launch configurations (AppImage, Flatpak, Native) for popular assistants, describing user-facing capabilities without internal protocol diagrams.
* **Storage Locations & Interoperability**: Exact file paths on disk and practical tips for using notes with external Markdown tools (Obsidian, Logseq, Syncthing, terminal tools).

### What to Exclude (and Relocate)
* **Internal Class Names & APIs**: Move references to internal classes (e.g., `MarkdownBuffer`, `NoteManager`, `Storage.vala`) to [`docs/architecture.md`](../../../docs/architecture.md).
* **Parser Internals**: Move discussions of token streams, AST nodes, dedenting logic, or HTML entity decoders to [`docs/architecture.md`](../../../docs/architecture.md).
* **D-Bus & IPC Plumbing**: Move session bus interfaces (`io.github.comicdeed.jots.Notes`), signal activation, and GApplication single-instance mechanics to [`docs/architecture.md`](../../../docs/architecture.md).
* **Multi-Agent Architecture & Protocol Specs**: Move Tier 1 vs Tier 2 agent taxonomy, subagent execution latency metrics, and JSON-RPC protocol specs to [`docs/development/mcp-server.md`](../../../docs/development/mcp-server.md).
* **Packaging & Sandbox Plumbing**: Move XDG portal background daemon hooks, AppDir bundle mechanics, and library packaging rules to [`docs/development/distribution.md`](../../../docs/development/distribution.md).

---

## ✍️ Voice, Tone & Formatting Standards

Adhere strictly to the [GNOME Developer Documentation Style Guidelines](https://developer.gnome.org/documentation/guidelines/devel-docs.html):

1. **Active Voice & Imperative Mood**: Write direct instructions (*"Click the title to rename the note"* instead of *"The note title can be renamed by clicking on it"*).
2. **Sentence-Cased Subheadings**: Use sentence-style capitalization for all section headings and table headers (e.g., `## 1. Getting started`, not `## 1. Getting Started`). Use Title Case only for the top-level document title (`# Jots User Guide`).
3. **Eliminate Fluff & Conversational Noise**: Remove placeholder phrasing (*"please note"*, *"at this time"*), promotional hype (*"powerful"*, *"seamlessly"*), and condescending adverbs (*"simply"*, *"just"*, *"easily"*).
4. **No Exclamation Points**: Keep technical prose calm, objective, and authoritative.
5. **Scannability**: Prefer short bullet points, tables, and code snippets over dense paragraphs with nested clauses.
6. **Machine-Scannable Directive Header**: Ensure all end-user guide documents start with an HTML comment block establishing audience attributes, scope, and style references to prevent future regression.

---

## ✅ Quality Gate & Review Checklist

Before finalizing any changes to end-user documentation, verify the following:

- [ ] **Audience Calibration**: Is the text free of developer jargon, class names, D-Bus interfaces, and parser internals?
- [ ] **Heading Casing**: Are all section headings (level 2 and below) formatted in sentence case?
- [ ] **Table of Contents Synchronization**: Do all table-of-contents links accurately match the section anchor IDs?
- [ ] **Relative Links**: Do all markdown links to other docs (e.g. `[MCP Server Guide](development/mcp-server.md)`) resolve to existing files?
- [ ] **Action-Oriented Shortcuts**: Does the shortcut table describe practical user actions rather than implementation details?
- [ ] **Directive Header Present**: Is the machine-scannable HTML guideline comment present at the top of the file?
