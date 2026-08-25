<div align="center">
  <img alt="Jots Icon" src="data/icons/default/hicolor/128.png" />
  <h1>Jots</h1>
  <p>Lightweight sticky notes application for the Linux desktop.</p>

  <a href="https://elementary.io">
    <img src="https://ellie-commons.github.io/community-badge.svg" alt="Made for elementary OS">
  </a>
  
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="data/screenshots/jots-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="data/screenshots/jots-light.png">
    <img class="center" src="data/screenshots/jots-light.png" alt="Jots screenshot">
  </picture>
</div>

---

> 📖 **User Guide**: Refer to the **[Jots User Guide](docs/user-guide.md)** for a complete overview of note operations, keyboard shortcuts, formatting, and AI automation.

---

## Key features

* 📝 **Live Markdown rendering**: Real-time syntax highlighting for headings (H1–H3), bold/italic/strikethrough emphasis, blockquotes, code spans, code fences, task lists (`- [ ]`, `- [x]`), and clickable links without modal preview toggles.
* 🎨 **10 pastel color themes**: Thoughtfully designed color palettes that adapt to light and dark system styles.
* 🔤 **Typography customization**: Custom proportional and code monospace font selection with automatic monospace catalog filtering.
* 🔒 **Scribbly privacy mode**: Focus-driven text obfuscation with handwritten squiggles (`Redacted Script`) to protect sensitive notes from shoulder surfing.
* 📂 **Markdown storage & interoperability**: Notes are stored as plain `.md` files with YAML front matter—directly compatible with **Obsidian**, **Logseq**, `git`, and backup tools.
* 🤖 **Native MCP server (`jots-mcp`)**: Built-in Model Context Protocol server enabling AI assistants (Claude Desktop, Cursor, Gemini CLI, Antigravity) to manage desktop notes in real time.
* ⚡ **Fast and lightweight**: Written in native Vala/GTK4 with sub-millisecond startup, zero heavy runtimes, and low memory usage.

---

## Installation and build instructions

Jots is distributed as a sandboxed Flatpak application:

* **Flathub**: [Download on Flathub](https://flathub.org/apps/io.github.comicdeed.jots)
* **AppCenter**: [Get it on AppCenter](https://appcenter.elementary.io/io.github.comicdeed.jots)
* **Local compilation**: Refer to the [Building Guide](docs/development/building.md) for native and sandbox compilation instructions.
* **Windows**: Experimental installers are available in the Releases section. Detailed MSYS2 build steps are available in the [Windows Build Guide](docs/development/windows.md).

---

## AI assistant and MCP automation

Jots includes a native [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server (`jots-mcp`) allowing AI assistants (Claude Desktop, Cursor, Gemini CLI, and Antigravity) to query, create, edit, search, and delete sticky notes live on the desktop.

See the **[MCP Integration Guide](docs/development/mcp-server.md)** or the **[User Guide AI Section](docs/user-guide.md#7-ai-assistant--mcp-integration)** for setup details.

---

## Markdown storage and Obsidian/Logseq interoperability

All notes are stored as individual `.md` Markdown files with standardized YAML front-matter headers containing note metadata (UUID, title, theme, zoom, and window dimensions):

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

### Storage paths
* **Flatpak sandbox**:
  `~/.var/app/io.github.comicdeed.jots/data/io.github.comicdeed.jots/notes/`
* **Native / system package**:
  `~/.local/share/io.github.comicdeed.jots/notes/`

---

## Documentation index

* **[User Guide](docs/user-guide.md)**: End-user documentation for note operations and shortcuts.
* **[System Architecture](docs/architecture.md)**: Component hierarchy, subsystem boundaries, and D-Bus IPC specifications.
* **[Product Roadmap](docs/roadmap.md)**: Graded backlog and development initiatives.
* **[MCP Integration Guide](docs/development/mcp-server.md)**: Setup instructions for AI assistant clients.
* **[Contributing and PR Guidelines](docs/development/pull-request-guidelines.md)**: Contribution checklist and pull request standards.

---

## Community and support

* **Discussions**: Ask questions or discuss new features in the [GitHub Discussions tab](https://github.com/comicdeed/jots/discussions).
* **Issue tracker**: Report bugs or suggest enhancements via the [Issues tab](https://github.com/comicdeed/jots/issues).
