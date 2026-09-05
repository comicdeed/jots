# Jots - Agent Development Guide

Welcome! This document provides core development guidelines, build commands, and links to specialized technical documentation for Jots.

---

## 🧭 Documentation & Task Map

To maintain focus and avoid context bloat, follow this task-based lookup policy:

### 🎯 When to Consult Specialized Docs:
* **Planning or Designing a Feature / Refactor**:
  * **UI, Widgets, Views, Chrome, or CSS**: **MUST consult** [`docs/development/ui-ux-guidelines.md`](docs/development/ui-ux-guidelines.md) (IA, relative contrast, multi-element factories) and [`docs/development/vala-coding-standards.md`](docs/development/vala-coding-standards.md) (GTK4 idioms, signal lifecycles, `VCS-30–35`) *before writing code*.
  * **Architecture, D-Bus IPC, or Storage Flows**: Consult [`docs/architecture.md`](docs/architecture.md) and [`docs/use-cases/README.md`](docs/use-cases/README.md).
* **Preparing Releases or Curating Release Notes**: Consult [`.agents/skills/release-notes/SKILL.md`](.agents/skills/release-notes/SKILL.md) and [`docs/development/release-workflow.md`](docs/development/release-workflow.md).
* **Auditing or Writing User-Facing Manuals**: Consult [`.agents/skills/user-guide-review/SKILL.md`](.agents/skills/user-guide-review/SKILL.md) and [`docs/user-guide.md`](docs/user-guide.md).

### 🚫 When NOT to Consult These Docs (Stay Lean & Fast):
* **Debugging & Bug Triage**: Do **not** load high-level design guidelines. Focus directly on reproduction steps, log traces, stack traces, and the specific faulty code path.
* **Running Builds & Test Suites**: Execute standard test commands directly without loading design docs.
* **Minor Text, Typo, or Asset Tweaks**: Edit directly without full architectural review.

### 📚 Documentation Map:
* **User Guide**: [`docs/user-guide.md`](docs/user-guide.md) — Comprehensive, single-page end-user guide covering note operations, keyboard shortcuts, formatting, and AI features.
* **System Architecture**: [`docs/architecture.md`](docs/architecture.md) — Comprehensive component hierarchy, subsystem boundaries, D-Bus service specs, sequence diagrams, and lifecycles.
* **Behavioral Use Cases**: [`docs/use-cases/README.md`](docs/use-cases/README.md) — Domain behavioral specifications (`UC-10` to `UC-70`) cross-referenced in unit tests.
* **MCP Integration Guide**: [`docs/development/mcp-server.md`](docs/development/mcp-server.md) — Setup instructions for Claude Desktop, Cursor, Devin Desktop, and Antigravity.
* **Roadmap & Idea Matrix**: [`docs/roadmap.md`](docs/roadmap.md) — Graded initiatives and feature backlog.
* **UI/UX Guidelines**: [`docs/development/ui-ux-guidelines.md`](docs/development/ui-ux-guidelines.md) — Canonical evolving guidance for interface decisions, settings design, IA grouping, canvas/chrome styling, relative contrast (`alpha(currentColor)`), and multi-element modularization.
* **Developer Setup & Tooling**: [`docs/development/setup.md`](docs/development/setup.md) — Workstation setup, Git branch guardrails, tooling prerequisites, and editor extensions.
* **Documentation Style**: [`docs/development/documentation-style.md`](docs/development/documentation-style.md) — GNOME developer style rules.
* **Release Workflow & Automation**: [`docs/development/release-workflow.md`](docs/development/release-workflow.md) — Release branching strategy, AppStream changelog curation, and automated multi-arch GitHub releases.
* **Pull Request Guidelines**: [`docs/development/pull-request-guidelines.md`](docs/development/pull-request-guidelines.md) — Contribution checklists and attribution standards.
* **Vala Coding Standards**: [`docs/development/vala-coding-standards.md`](docs/development/vala-coding-standards.md) — **Read before writing any widget or signal connection.** Standing rules for signal lifecycle (VCS-01–04), null safety & type validation (VCS-12–14), UTF-8 safety (VCS-10/11), Pango markup (VCS-20), GObject lifecycle, GTK4 idioms & multi-element factories (VCS-30–35), error handling (VCS-50–52), and architectural guardrails (VCS-40/41).

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

## 📦 Post-Clone Setup, Standard Build/Test Workflows

### 1. Enable Repository Git Hooks (Post-Clone)
After cloning the repository, configure Git to use the tracked hooks in `.githooks/` to activate the local branch guardrail:
```bash
git config core.hooksPath .githooks
```

### 2. Standard non-CI workflow model (humans and agents)
Use this decision model for compile, run, and test.

1. **Native mode (optional acceleration path when host toolchain is compatible)**
```bash
meson setup builddir --prefix=/usr --buildtype=debug -Dprofile=linux
meson compile -C builddir
GSK_RENDERER=cairo GTK_A11Y=none xvfb-run -a meson test -C builddir --verbose
```

Use native mode only when the host environment satisfies the repository toolchain requirements (notably GTK4 >= 4.14 and pkg-config visibility for system GTK libraries).

2. **AppImage mode (formal packaging path, mode-specific verification)**
Stable package:
```bash
docker compose run --rm appimage
```
Devel package:
```bash
docker compose run --rm appimage-devel
```
Cached devel package rebuild (faster repeat packaging):
```bash
docker compose run --rm appimage-devel-cached
```
Containerized Meson canary tests:
```bash
docker compose run --rm meson-test
```
Build devel AppImage for embedded test runner:
```bash
docker compose run --rm appimage-devel
```
Direct devel AppImage test execution after build (faster repeat runs and selector support):
```bash
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests -p /McpProtocol/UC_70_10_10/InitializeHandshake
```
Direct script fallback only when Compose is unavailable:
```bash
./packaging/appimage/build-appimage.sh
./packaging/appimage/build-appimage.sh --devel
```

3. **Flatpak mode (maintained parity with AppImage)**
Devel build + run + tests:
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir packaging/flatpak/io.github.comicdeed.jots.devel.yml
flatpak run io.github.comicdeed.jots.devel
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
```
Direct Flatpak devel test reruns with selectors:
```bash
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel -p /McpProtocol/UC_70_10_10/InitializeHandshake
```
Stable build + run:
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir packaging/flatpak/io.github.comicdeed.jots.yml
flatpak run io.github.comicdeed.jots
```
Flatpak MCP server (devel):
```bash
flatpak run --command=jots-mcp io.github.comicdeed.jots.devel
```

Default to package-mode workflows for day-to-day validation. Use native mode as an optional fast path only when host compatibility is confirmed.

Escalate from native-only to package-mode verification whenever a change touches packaging-sensitive behavior (AppRun or packaging scripts, launch semantics, D-Bus/MCP, portal/autostart, sandbox permissions, install/runtime paths).

Targeted package-mode tests (for example devel AppImage embedded tests and Flatpak devel tests) must run in their full packaged runtime setup because these checks can depend on packaging-specific environment details such as session bus wiring, sandbox permissions, and desktop portal behavior.

Artifacts are written to `dist/`.

### 3. Windows Packaging (Experimental)
For local Windows packaging, follow `docs/development/windows.md` in an MSYS2 UCRT64 shell.

---

## 💡 Development Guidelines

* **UI/UX Aesthetic Constraints**: Jots is minimal by design. Avoid adding heavy components.
* **Encapsulation & Boundaries**: Keep storage mechanics encapsulated in `Storage.vala`. External tools interact strictly via `NoteService` D-Bus IPC.
* **Test Skipping for Non-Built Changes**: Do NOT run local test suites (`docker compose run --rm meson-test`, native `meson test`, AppImage/Flatpak test runners) when only documentation or non-built text assets (`*.md`, `docs/**`, `README.md`, `CONTRIBUTING.md`) are modified. Reserve test suite execution for changes affecting executable code, build configurations, metadata, or packaging scripts.
* **CI Skip Token for Non-Built Changes**: For docs-only or other non-built changes (for example Markdown/text updates), append `[skip ci]` to the commit subject to avoid unnecessary GitHub Actions runs.
  - **Safe scope**: Documentation/content-only paths such as `*.md`, `docs/**`, `README.md`, `CONTRIBUTING.md`, and similar non-executable text assets.
  - **Do NOT skip CI** when any build/runtime/test/release path changes, including `src/**`, `tests/**`, `data/**`, `po/**`, `meson.build`, `meson_options.txt`, `compose.yaml`, `packaging/**`, `.github/workflows/**`, or scripts.
* **Commit Messages and Release Notes**: Release-note curation reads commit history. For user-visible `feat` and `fix` commits, write an outcome-focused subject and a brief body that states the default behavior, user choices, and any meaningful live-update or compatibility behavior. Keep the body to the details a release-note editor needs; omit test, refactor, and implementation mechanics. Routine internal commits do not need a body unless the subject alone cannot explain the intent.
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
* **System-Wide Codebase Audit**: For periodic full-repository health, architectural boundary, and technical debt assessments across all modules, use [`.agents/skills/codebase-audit/SKILL.md`](.agents/skills/codebase-audit/SKILL.md).
* **End-User Documentation Review**: For auditing, updating, or calibrating user-facing manuals and guides against essential reader attributes and GNOME doc style, use [`.agents/skills/user-guide-review/SKILL.md`](.agents/skills/user-guide-review/SKILL.md).
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
  3. For intermediate non-critical release-branch commits, include `[skip ci]` in the commit subject to avoid unnecessary CI runs.
  4. Run full CI only when the release branch is ready for validation before merge to `main`.
  5. Execute the release notes skill [`.agents/skills/release-notes/SKILL.md`](.agents/skills/release-notes/SKILL.md):
     - Run `git log <base-tag>..HEAD --oneline --no-merges`
     - Add curated `<release>` entry to `data/jots.metainfo.xml.in.in`.
     - Update [`docs/user-guide.md`](docs/user-guide.md) if shortcuts or UI features changed.
  6. Commit: `chore(release): prepare X.Y.Z[-beta.N] release`.
  7. Open Pull Request: `release/X.Y.Z[-beta.N]` $\rightarrow$ `main`.
* **Automated Release on PR Merge**:
  - Merging the `release/*` PR into `main` automatically triggers `.github/workflows/release.yml`:
    1. Extracts the version and automatically creates & pushes git tag `X.Y.Z[-beta.N]` to `main`.
    2. Builds multi-architecture AppImages (`x86_64`, `aarch64`), Flatpak standalone bundles, and Windows installers.
    3. Extracts release notes directly from `data/jots.metainfo.xml.in.in` and creates the GitHub Release with all compiled assets attached.
    4. Automatically prunes older historical pre-releases on GitHub (retaining a sliding window of the 3 most recent) while leaving git tags intact.
    5. Automatically merges `main` back into `develop` to keep version bumps and metadata synchronized.

