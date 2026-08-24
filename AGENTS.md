# Jots - Agent Development Guide

Welcome! This document provides core development guidelines, build commands, and links to specialized technical documentation for Jots.

---

## 🧭 Progressive Documentation Index

To maintain focus and avoid context bloat, refer to specialized documentation on demand:

* **User Guide**: [`docs/user-guide.md`](docs/user-guide.md) — Comprehensive, single-page end-user guide covering note operations, keyboard shortcuts, formatting, and AI features.
* **System Architecture**: [`docs/architecture.md`](docs/architecture.md) — Comprehensive component hierarchy, subsystem boundaries, D-Bus service specs, sequence diagrams, and lifecycles.
* **Behavioral Use Cases**: [`docs/use-cases/README.md`](docs/use-cases/README.md) — Domain behavioral specifications (`UC-10` to `UC-70`) cross-referenced in unit tests.
* **MCP Integration Guide**: [`docs/development/mcp-server.md`](docs/development/mcp-server.md) — Setup instructions for Claude Desktop, Cursor, Gemini CLI, and Antigravity.
* **Roadmap & Idea Matrix**: [`docs/roadmap.md`](docs/roadmap.md) — Graded initiatives and feature backlog.
* **Documentation Style**: [`docs/development/documentation-style.md`](docs/development/documentation-style.md) — GNOME developer style rules.
* **Pull Request Guidelines**: [`docs/development/pull-request-guidelines.md`](docs/development/pull-request-guidelines.md) — Contribution checklists and attribution standards.

---

## 🏗️ Architecture Summary

Jots is a lightweight GTK4/Granite 7 sticky notes app and MCP server written entirely in **Vala**:
1. **`Jots.Application`**: Main entry point, GSettings/theme management, and D-Bus registration.
2. **`Jots.NoteManager`**: Central coordinator managing active windows (`open_notes`) and debounced saving.
3. **`Jots.NoteService`**: Native D-Bus service (`io.github.comicdeed.jots.Notes`) for real-time desktop IPC.
4. **`Jots.McpMain` (`jots-mcp`)**: Native standalone Model Context Protocol server over `stdio`.
5. **`Jots.Storage`**: Private JSON persistence layer.

*(See [`docs/architecture.md`](docs/architecture.md) for full component maps, sequence flows, and guardrail limits.)*

---

## 📦 Build & Test Workflows

### 1. Build and Install Jots (Flatpak Sandbox)
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir io.github.comicdeed.jots.devel.yml
```

### 2. Run Jots Locally
```bash
flatpak run io.github.comicdeed.jots.devel
```

### 3. Run Native MCP Server in Flatpak
```bash
flatpak run --command=jots-mcp io.github.comicdeed.jots.devel
```

### 4. Run Canary Unit Tests
```bash
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
```

---

## 💡 Development Guidelines

* **UI/UX Aesthetic Constraints**: Jots is minimal by design. Avoid adding heavy components.
* **Encapsulation & Boundaries**: Keep storage mechanics encapsulated in `Storage.vala`. External tools interact strictly via `NoteService` D-Bus IPC.
* **Compilation Warnings**: The build uses `-w` in `meson.build` to suppress Vala-generated C compiler noise.
* **Test & Use-Case Cross-Referencing**: When writing unit tests in `tests/`, embed the permanent use-case identifier (`/<Component>/UC_XX_YY_ZZ/<ScenarioName>`) and link to `docs/use-cases/`.
* **User Guide Synchronization**: Whenever modifying user-facing features, keyboard shortcuts, or settings, update [`docs/user-guide.md`](docs/user-guide.md).
* **Honest Attribution**: When opening a PR, include the attribution block in `docs/development/pull-request-guidelines.md`.
