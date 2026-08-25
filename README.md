<div align="center">
  <img alt="Jots Icon" src="data/icons/default/hicolor/128.png" />
  <h1>Jots</h1>
  <h3>A simple, lightweight sticky notes application for the Linux desktop</h3>

  <a href="https://elementary.io">
    <img src="https://ellie-commons.github.io/community-badge.svg" alt="Made for elementary OS">
  </a>
  
  <span align="center">
    <img class="center" src="data/screenshots/spread.png" alt="Jots screenshot">
  </span>
</div>

<br/>

> 📖 **New to Jots?** Read the **[Jots User Guide](docs/user-guide.md)** for a complete overview of features, keyboard shortcuts, smart lists, and AI agent automation.

<br/>

## ✨ Key Features

* 📝 **Live Markdown Rendering**: Real-time syntax highlighting for headings (H1–H3), bold/italic/strikethrough, blockquotes, code spans, code fences, checklists (`- [ ]`), and clickable links without modal preview toggles.
* 🎨 **10 Pastel Color Themes**: Beautiful, distraction-free color palettes that adapt seamlessly to Light and Dark system styles.
* 🔤 **Typography Customization**: Select custom proportional and code monospace fonts with automatic monospace catalog filtering.
* 🔒 **Scribbly Privacy Mode**: Automatic focus-driven text obfuscation with handwritten squiggles (`Redacted Script`) to protect sensitive notes from shoulder surfing.
* 📂 **Markdown Storage & Interoperability**: Notes are stored as plain `.md` files with YAML front matter—directly compatible with **Obsidian**, **Logseq**, `git`, and backup tools.
* 🤖 **Native MCP Server (`jots-mcp`)**: Built-in Model Context Protocol server enabling AI assistants (Claude Desktop, Cursor, Gemini CLI, Antigravity) to manage your desktop notes in real time.
* ⚡ **Lightning Fast & Lightweight**: Written in native Vala/GTK4 with sub-millisecond startup, zero heavy runtimes, and low memory usage.

<br/>

## 🦺 Installation & Compilation

Jots is distributed as a sandboxed Flatpak application:

* **Flathub**: [Download on Flathub](https://flathub.org/apps/io.github.comicdeed.jots)
* **AppCenter**: [Get it on AppCenter](https://appcenter.elementary.io/io.github.comicdeed.jots)
* **Local Build / Compilation**: Refer to the [Building Guide](docs/development/building.md) for native and sandbox compilation instructions.
* **Windows**: Basic experimental installers are available in the Releases section. Detailed MSYS2 build steps are available in the [Windows Build Guide](docs/development/windows.md).

<br/>

## 🤖 AI Assistant & MCP Automation

Jots includes a native [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server (`jots-mcp`) allowing AI assistants (Claude Desktop, Cursor, Gemini CLI, and Antigravity) to query, create, edit, search, and delete sticky notes live on your desktop.

See the **[MCP Integration Guide](docs/development/mcp-server.md)** or the **[User Guide AI Section](docs/user-guide.md#7-ai-assistant--mcp-integration)** for setup details.

<br/>

## 💾 Notes Storage & Obsidian Interoperability

All notes are stored as individual, human-readable `.md` Markdown files with standardized YAML front-matter headers containing note metadata (UUID, title, theme, zoom, and window dimensions):

```markdown
---
id: "3ba7ca8a-d40c-45b9-a9f8-94c15b853e2d"
title: "Project Ideas"
theme: "MINT"
monospace: false
zoom: 100
width: 380
height: 320
---
# Architecture Overview
- [x] Switch to Markdown storage
- [ ] Implement full-text search popover
```

### Storage Paths
* **Flatpak Sandbox**:
  `~/.var/app/io.github.comicdeed.jots/data/io.github.comicdeed.jots/notes/`
* **Native / System Package**:
  `~/.local/share/io.github.comicdeed.jots/notes/`

<br/>

## ❓ Support & Discussions
* **Discussions**: Ask questions or discuss new features in the [GitHub Discussions tab](https://github.com/comicdeed/jots/discussions).
* **Issue Tracker**: Report bugs or suggest enhancements via the [Issues tab](https://github.com/comicdeed/jots/issues).
