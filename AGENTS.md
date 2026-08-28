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
* **Developer Setup & Tooling**: [`docs/development/setup.md`](docs/development/setup.md) — Workstation setup, Git branch guardrails, tooling prerequisites, and editor extensions.
* **Documentation Style**: [`docs/development/documentation-style.md`](docs/development/documentation-style.md) — GNOME developer style rules.
* **Release Workflow & Automation**: [`docs/development/release-workflow.md`](docs/development/release-workflow.md) — Release branching strategy, AppStream changelog curation, and automated multi-arch GitHub releases.
* **Pull Request Guidelines**: [`docs/development/pull-request-guidelines.md`](docs/development/pull-request-guidelines.md) — Contribution checklists and attribution standards.
* **Vala Coding Standards**: [`docs/development/vala-coding-standards.md`](docs/development/vala-coding-standards.md) — **Read before writing any widget or signal connection.** Standing rules for signal lifecycle (VCS-01–04), null safety & type validation (VCS-12–14), UTF-8 safety (VCS-10/11), Pango markup (VCS-20), GObject lifecycle & GTK4 idioms (VCS-30–33), error handling (VCS-50–52), and architectural guardrails (VCS-40/41).

---

## 🏗️ Architecture Summary

Jots is a lightweight GTK4 sticky notes app and MCP server written entirely in **Vala**:
1. **`Jots.Application`**: Main entry point, GSettings/theme management, and D-Bus registration.
2. **`Jots.NoteManager`**: Central coordinator managing active windows (`open_notes`) and debounced saving.
3. **`Jots.NoteService`**: Native D-Bus service (`io.github.comicdeed.jots.Notes`) for real-time desktop IPC.
4. **`Jots.McpMain` (`jots-mcp`)**: Native standalone Model Context Protocol server over `stdio`.
5. **`Jots.Storage`**: Private JSON persistence layer.

*(See [`docs/architecture.md`](docs/architecture.md) for full component maps, sequence flows, and guardrail limits.)*

---

## 📦 Post-Clone Setup & Build Workflows

### 1. Enable Repository Git Hooks (Post-Clone)
After cloning the repository, configure Git to use the tracked hooks in `.githooks/` to activate the local branch guardrail:
```bash
git config core.hooksPath .githooks
```

### 2. Build and Install Jots (Flatpak Sandbox)
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
* **CI Skip Token for Non-Built Changes**: For docs-only or other non-built changes (for example Markdown/text updates), append `[skip ci]` to the commit subject to avoid unnecessary GitHub Actions runs.
  - **Safe scope**: Documentation/content-only paths such as `*.md`, `docs/**`, `README.md`, `CONTRIBUTING.md`, and similar non-executable text assets.
  - **Do NOT skip CI** when any build/runtime/test/release path changes, including `src/**`, `tests/**`, `data/**`, `po/**`, `meson.build`, `meson.options`, `compose.yaml`, `io.github.comicdeed.jots*.yml`, `packaging/**`, `.github/workflows/**`, or scripts.
* **Docker & CI Packaging Parity (Crucial Rule)**:
  - **Zero Dependency Drift**: Whenever adding or updating build packages, libraries, or asset engines (e.g., `librsvg2-dev`, `librsvg2-common`, `libportal`, font rendering engines) in `packaging/appimage/Dockerfile` or `compose.yaml`, you **MUST simultaneously update the runner dependencies in `.github/workflows/CI.yml` and `.github/workflows/release.yml`**.
  - **Hard Packaging Guardrails**: Packaging scripts like `packaging/appimage/build-appimage.sh` must include strict assertions (e.g., checking that `libpixbufloader-svg.so` and runtime libraries exist in `AppDir`) so that missing dependencies fail fast in CI instead of producing broken packages.
* **Test & Use-Case Cross-Referencing**: When writing unit tests in `tests/`, embed the permanent use-case identifier (`/<Component>/UC_XX_YY_ZZ/<ScenarioName>`) and link to `docs/use-cases/`.
* **User Guide Synchronization**: Whenever modifying user-facing features, keyboard shortcuts, or settings, update [`docs/user-guide.md`](docs/user-guide.md).
* **SPDX Attribution Maintenance**: For changes to source, tests, scripts, CSS, or build/config files, preserve existing SPDX headers and add/update `SPDX-FileCopyrightText` entries for new contributors when they make substantive edits.
* **Honest Attribution**: When opening a PR, include the attribution block in `docs/development/pull-request-guidelines.md`.

---

## 🔍 Code Review & Verification Convention

* **Senior Review Subagent**: After implementing any significant feature or architectural refactor, conduct a thorough Senior Vala code review using the project skill [`.agents/skills/vala-code-review/SKILL.md`](.agents/skills/vala-code-review/SKILL.md).
* **Smart Confirmation Protocol**: **Always ask the user for confirmation before launching the automated code review subagent**, as the user may prefer to manually inspect changes, test UI behavior interactively, or provide immediate feedback first.

---

## 🚀 Git Release Workflow & Release Automation

* **Branching Strategy**:
  - `main`: Protected production branch containing verified **Stable releases**.
  - `develop`: Primary integration branch where `feat/*` and `fix/*` PRs land.
  - `release/X.Y.Z[-beta.N]`: Short-lived preparation branch cut from `develop`.
* **Release Preparation on `release/*` Branch**:
  1. Cut `release/X.Y.Z[-beta.N]` from `develop`.
  2. Bump `version: 'X.Y.Z[-beta.N]'` in `meson.build`.
  3. Execute the release notes skill [`.agents/skills/release-notes/SKILL.md`](.agents/skills/release-notes/SKILL.md):
     - Run `git log <base-tag>..HEAD --oneline --no-merges`
     - Add curated `<release>` entry to `data/jots.metainfo.xml.in.in`.
     - Update [`docs/user-guide.md`](docs/user-guide.md) if shortcuts or UI features changed.
  4. Commit: `chore(release): prepare X.Y.Z[-beta.N] release`.
  5. Open Pull Request: `release/X.Y.Z[-beta.N]` $\rightarrow$ `main`.
* **Automated Release on PR Merge**:
  - Merging the `release/*` PR into `main` automatically triggers `.github/workflows/release.yml`:
    1. Extracts the version and automatically creates & pushes git tag `X.Y.Z[-beta.N]` to `main`.
    2. Builds multi-architecture AppImages (`x86_64`, `aarch64`), Flatpak standalone bundles, and Windows installers.
    3. Extracts release notes directly from `data/jots.metainfo.xml.in.in` and creates the GitHub Release with all compiled assets attached.
    4. Automatically merges `main` back into `develop` to keep version bumps and metadata synchronized.

