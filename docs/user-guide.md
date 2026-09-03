<!-- 
  DOC-DIRECTIVE: JOTS USER GUIDE
  - Target Audience: Everyday Linux desktop users comfortable with Markdown notes and basic Git repository URLs. Not software developers.
  - Style Guide: GNOME Developer Documentation Style (docs/development/documentation-style.md).
  - Tone: Task-oriented, direct, active voice, sentence-cased subheadings. No conversational filler or exclamation marks.
  - Content Scope: Include UI actions, shortcuts, formatting syntax, themes, privacy toggles, backup setup, and basic AI client commands.
  - Exclusions: Do NOT include internal class names (e.g. MarkdownBuffer), D-Bus IPC details, GApplication activation, or multi-agent taxonomy. Relocate technical internals to docs/architecture.md and docs/development/mcp-server.md.
  - Skill Reference: .agents/skills/user-guide-review/SKILL.md
-->

# Jots User Guide

Jots is a lightweight, distraction-free sticky notes application for Linux. It keeps your thoughts, checklists, and snippets accessible right on your desktop while staying out of your way.

---

## Table of contents

* [1. Getting started](#1-getting-started)
* [2. Keyboard shortcuts](#2-keyboard-shortcuts)
* [3. Markdown formatting and smart paste](#3-markdown-formatting-and-smart-paste)
* [4. Themes and typography](#4-themes-and-typography)
* [5. Privacy and note protection](#5-privacy-and-note-protection)
* [6. Backups and Git sync](#6-backups-and-git-sync)
* [7. AI assistant integration (MCP)](#7-ai-assistant-integration-mcp)
* [8. File storage and interoperability](#8-file-storage-and-interoperability)

---

## 1. Getting started

### Creating and managing notes
* **New note**: Click **`+`** in the bottom toolbar or press **`Ctrl + N`**. Each note opens in its own floating window that you can place anywhere on your desktop.
* **Edit title**: Click the title in the top bar, type the new name, and press **`Enter`** (or click outside).
* **Delete note**: Click the **Trash** icon in the bottom toolbar or press **`Ctrl + W`**.
* **Restore note**: Press **`Ctrl + R`** immediately after deleting a note to reopen it with its content, color, and window position restored.

### Searching notes
* Press **`Ctrl + F`** (or **`Ctrl + Shift + F`**) to open the search bar.
* Search matches titles and note contents across both open desktop notes and closed saved notes on disk.
* Use the **`Up`** / **`Down`** arrows to browse matching results and press **`Enter`** to open or focus the note.

---

## 2. Keyboard shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Ctrl + N`** | **New note** | Opens a new sticky note with a random pastel color. |
| **`Ctrl + F`** / **`Ctrl + Shift + F`** | **Search** | Opens full-text search across active and saved notes. |
| **`Ctrl + L`** | **Edit title** | Focuses the note title for editing (`Enter` to confirm). |
| **`Ctrl + W`** | **Delete note** | Deletes and closes the focused note window. |
| **`Ctrl + R`** | **Restore note** | Restores the last deleted note with its content and position. |
| **`Ctrl + S`** | **Save now** | Immediately commits all pending note changes to disk. |
| **`Shift + F12`** | **Toggle bullet list** | Adds or removes list bullets on the current line or selection. |
| **`Ctrl + D`** / **`Ctrl + Enter`** | **Toggle checklist** | Toggles `- [ ]` and `- [x]`, or converts text into a task item. |
| **`Ctrl + V`** | **Smart paste** | Pastes text and converts rich web formatting into clean Markdown. |
| **`Ctrl + Shift + V`** | **Raw paste** | Pastes exact clipboard text without formatting changes. |
| **`Ctrl + M`** | **Toggle monospace** | Switches the note to fixed-width monospace font. |
| **`Ctrl + G`** / **`Ctrl + O`** | **Note menu** | Opens the color palette and note settings popover. |
| **`Ctrl + .`** | **Emoji picker** | Opens the system emoji picker. |
| **`Ctrl + H`** | **Scribbly privacy** | Toggles text obfuscation on unfocused notes. |
| **`Ctrl + T`** | **Toggle toolbar auto-hide** | Controls whether the bottom toolbar hides when unfocused. |
| **`Ctrl + P`** | **Preferences** | Opens the global Preferences window. |
| **`Ctrl + +`** | **Zoom in** | Increases note text size. |
| **`Ctrl + -`** | **Zoom out** | Decreases note text size. |
| **`Ctrl + 0`** / **`Ctrl + =`** | **Reset zoom** | Resets text zoom to 100%. |
| **`Ctrl + Scroll`** | **Smooth zoom** | Scales text dynamically with your mouse wheel or touchpad. |
| **`Ctrl + Click`** | **Open link** | Opens a link or email address in your default application. |
| **`F1`** | **Cheat sheet** | Opens the built-in reference note with shortcuts and tips. |
| **`Ctrl + Q`** | **Quit** | Exits Jots. |

---

## 3. Markdown formatting and smart paste

Jots renders Markdown live as you type, giving you rich visual styling without a separate preview pane.

| Markdown syntax | Example | Live behavior |
| :--- | :--- | :--- |
| **Headings** | `# Heading 1`<br>`## Heading 2`<br>`### Heading 3` | Scaled headers with bold styling and subtle markers. |
| **Bold** | `**bold text**` | Bold font weight. |
| **Italic** | `*italic text*` | Slanted emphasis font. |
| **Strikethrough** | `~~strikethrough~~` | Horizontal line through text. |
| **Checklists** | `- [ ] Pending item`<br>`- [x] Done item` | Clickable checkboxes with auto-indentation. Completed items are automatically struck through. |
| **Bullet lists** | `• Item` or `- Item` | Automatic indentation and smart continuation on `Enter`. |
| **Quotes** | `> Quoted text` | Italicized blockquote styling. |
| **Inline code** | `` `const x = 42;` `` | Monospace font with background highlight pill. |
| **Code blocks** | ```` ```python ````<br>`print("Hello")`<br>```` ``` ```` | Multi-line monospace code box with subtle background tint. |
| **Links** | `https://example.com`<br>`[Site](https://...)` | Clickable links (**`Ctrl + Click`** opens in default browser). |

### Smart paste (`Ctrl + V`)
* **Web and rich-text conversion**: Pasting formatted text from a browser, document, or chat converts it into clean Markdown bullets, headings, and links.
* **Code block protection**: Pasting inside backticks or code blocks automatically bypasses formatting so your code is pasted verbatim.
* **Raw paste bypass (`Ctrl + Shift + V`)**: Use **`Ctrl + Shift + V`** (or right-click $\rightarrow$ *Paste Without Formatting*) to paste raw unformatted text.

---

## 4. Themes and typography

### 12 Pastel color themes
Jots includes 12 pastel colors that automatically adjust contrast for system Light and Dark modes:

* 🍌 **Banana**
* 🍊 **Tangerine**
* 🍑 **Peach**
* 🍉 **Watermelon**
* 🍬 **Bubblegum**
* 💜 **Lavender**
* 🌊 **Ocean**
* 🫧 **Sea Glass** *(default)*
* 🍃 **Mint**
* 🍐 **Pear**
* 🪨 **Pebble**
* ⚫ **Graphite**

To change a note's theme, click the **Menu button** in the bottom-right corner (or press **`Ctrl + G`**) and select a color. New notes pick a non-repeating random color to keep your desktop vibrant.

### Font customization
Open **Preferences $\rightarrow$ Appearance** to customize typography across all notes:
* **General font**: Select your preferred system font and size (e.g. *Inter*, *Cantarell*, *Ubuntu*, *Roboto*) for regular notes.
* **Code font**: Select a fixed-width typeface (e.g. *JetBrains Mono*, *Fira Code*, *Hack*) for code blocks and monospace notes.
* **Monospace note toggle (`Ctrl + M`)**: Press **`Ctrl + M`** on any note to display the entire note in your selected monospace code font.

---

## 5. Privacy and note protection

* **Scribbly privacy mode (`Ctrl + H`)**: Obfuscates note text with a handwritten scribble effect whenever a note loses focus. Focusing or hovering over the note restores clear readable text.
* **Lock note (read-only)**: Open the note menu (**`Ctrl + G`**) and toggle **Lock Note** to protect reference material from accidental edits.
* **Always visible exemption**: If Scribbly mode is enabled globally, you can mark specific notes as **Always Visible** in their note menu to keep them readable even when unfocused.
* **Toolbar auto-hide (`Ctrl + T`)**: The bottom formatting bar smoothly fades out when a note loses focus. Focusing the note brings the toolbar back immediately.
* **Autostart on login**: Enable **Autostart** in Preferences so all open sticky notes are automatically restored when you log into your desktop.
* **Import from Jorts**: If you previously used the Jorts sticky notes app, click **Import from Jorts** in Preferences to copy your existing notes over non-destructively.

---

## 6. Backups and Git sync

Jots includes built-in Git backup support to keep your notes synchronized and version-controlled.

### Setting up Git sync
1. Open **Preferences $\rightarrow$ Backup & Sync**.
2. Enter your remote Git repository URL (HTTPS or SSH, e.g., `git@github.com:username/notes.git` or `https://gitlab.com/username/notes.git`).
3. Click **Test connection** to verify authentication and reachability.
4. Choose an automatic sync schedule (e.g. on every change, hourly, or daily), or click **Sync now** at any time.

### Sync status indicators
* **Ready / Synced**: All local notes are committed and synchronized with your remote repository.
* **Syncing**: Local changes are being committed and pushed.
* **Diverged**: The remote repository contains changes that conflict with local notes. Jots flags this so you can inspect your files safely.

---

## 7. AI assistant integration (MCP)

Jots includes a built-in [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server. This allows AI coding assistants (such as Claude Code, Cursor, Devin, and Claude Desktop) to create, read, search, and organize your desktop notes.

### Launch commands for AI clients

Add Jots to your AI client's MCP configuration using the command for your package format:

* **AppImage**:
  ```json
  {
    "mcpServers": {
      "jots": {
        "command": "/path/to/Jots.AppImage",
        "args": ["--mcp"]
      }
    }
  }
  ```
* **Flatpak**:
  ```json
  {
    "mcpServers": {
      "jots": {
        "command": "flatpak",
        "args": ["run", "--command=jots-mcp", "io.github.comicdeed.jots"]
      }
    }
  }
  ```
* **Native package**:
  ```json
  {
    "mcpServers": {
      "jots": {
        "command": "jots-mcp"
      }
    }
  }
  ```

### What AI assistants can do
With MCP enabled, your assistant can:
* Search and read your notes for project context or todo lists.
* Create new sticky notes on your desktop during a workflow.
* Update checklists and append notes in real time.

For full protocol specifications and agent configurations, see the [MCP Server Guide](development/mcp-server.md).

---

## 8. File storage and interoperability

### Plain Markdown files
Every sticky note is stored as an individual, standard Markdown (`.md`) file with lightweight YAML front-matter headers for window settings:

```markdown
---
id: "project-ideas~a1b2c3"
title: "Project Ideas"
theme: "MINT"
monospace: false
zoom: 100
width: 380
height: 320
---
# Architecture Overview
- [x] Switch to Markdown storage
- [x] Native MCP AI assistant integration
- [ ] Central Note Organizer library
```

### Storage locations

* **Native / AppImage packages**:
  ```text
  ~/.local/share/io.github.comicdeed.jots/notes/
  ```
* **Flatpak packages**:
  ```text
  ~/.var/app/io.github.comicdeed.jots/data/io.github.comicdeed.jots/notes/
  ```

### Interoperability with other tools
Because notes are standard Markdown files on disk:
* **Obsidian & Logseq**: You can point external Markdown knowledge bases or vaults to your Jots notes folder.
* **Custom sync scripts**: You can synchronize your notes across machines using Syncthing, Nextcloud, or standard shell scripts.
* **Git CLI**: You can run `git log`, `git diff`, or manage your notes directory directly from your terminal.
