<div align="center">
  <img alt="Jots Icon" src="data/icons/default/hicolor/128.png" />
  <h1>Jots</h1>
  <p>Lightweight sticky notes application for the Linux desktop.</p>
  
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
* 📂 **Markdown storage & interoperability**: Notes are stored as standard plain `.md` files with YAML front matter—enabling integration with external Markdown editors, knowledge bases (such as Obsidian or Logseq), `git`, and backup tools.
* 🤖 **Native MCP server (`jots-mcp`)**: Built-in Model Context Protocol server enabling AI assistants (Claude Desktop, Cursor, Gemini CLI, Antigravity) to manage desktop notes in real time.
* ⚡ **Fast and lightweight**: Written in native Vala/GTK4 with sub-millisecond startup, zero heavy runtimes, and low memory usage.

---

## Installation and quick start

Jots is currently Linux-first. AppImage and Flatpak are the supported distribution paths. Windows installers are published for early access but are currently experimental and untested.

**Recommended (Primary Distribution):**

<a href="https://github.com/comicdeed/jots/releases/latest">
  <img src="data/badges/download-appimage.svg" alt="Download AppImage" width="280" />
</a>

* **Linux AppImage (Recommended, Click-and-Run)**: Download `Jots-<version>-<arch>.AppImage` (currently `Jots-<version>-x86_64.AppImage` or `Jots-<version>-aarch64.AppImage`) from the [latest release](https://github.com/comicdeed/jots/releases/latest), make it executable (`chmod +x Jots-*.AppImage`), and run directly on any Linux distribution without installation.
* **Linux Flatpak (Alternative)**: Download `io.github.comicdeed.jots-<version>-x86_64.flatpak` from the [latest release](https://github.com/comicdeed/jots/releases/latest) and install with `flatpak install io.github.comicdeed.jots-*.flatpak`.
* **Local compilation**: Refer to the [Developer Setup Guide](docs/development/setup.md) or [Building Guide](docs/development/building.md) for compilation instructions.
* **Windows (Experimental, Untested)**: Download `Jots-<version>-Installer.exe` (x86_64 only) from the [latest release](https://github.com/comicdeed/jots/releases/latest) for early testing (see the [Windows Build Guide](docs/development/windows.md)).

---

## AI assistant and MCP automation

Jots includes a native [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server (`jots-mcp`) allowing AI assistants (Claude Desktop, Cursor, Gemini CLI, and Antigravity) to query, create, edit, search, and delete sticky notes live on the desktop.

For setup, use the canonical **[MCP Integration Guide](docs/development/mcp-server.md#2-client-configuration-examples)**.

---

## Markdown storage and tool interoperability

All notes are stored as individual `.md` Markdown files with standardized YAML front-matter headers containing note metadata (UUID, title, theme, zoom, and window dimensions). Because notes are saved in plain text, you can read them with standard text tools, version control them with Git, or potentially integrate them into personal knowledge base directories (such as Obsidian or Logseq):

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
