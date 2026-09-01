# Developer Environment & Tooling Setup Guide

This guide describes how to set up your local development workstation, configure Git guardrails, install IDE tooling, and prepare build runtimes for contributing to **Jots** (`io.github.comicdeed.jots`).

---

## 1. Repository Setup & Git Guardrails (Post-Clone)

Immediately after cloning the repository, configure Git to use the tracked hooks in `.githooks/` to activate local branch guardrails:

```bash
# Enable tracked repository hooks
git config core.hooksPath .githooks

# Verify branch checkout is on develop
git checkout develop
```

### Git Branching Model & Guardrails
* **`develop`**: The primary integration branch. All feature branches (`feat/*`) and bugfix branches (`fix/*`) branch from and merge into `develop`.
* **`main`**: The protected production branch representing tagged stable releases. Direct pushes to `main` are blocked both locally via `.githooks/pre-push` and remotely via GitHub branch protection rules.

---

## 2. Tooling Prerequisites

### A. Docker + Compose (Primary for Local AppImage Packaging)
Use containerized packaging first for repeatable host-independent AppImage outputs:

```bash
docker --version
docker compose version
```

All day-to-day local AppImage packaging commands in this repository assume `docker compose`.

### B. Flatpak Sandbox Environment (Recommended for App Runtime and UI Testing)
Flatpak is the standard development and debugging environment for Jots. Ensure `flatpak` and `flatpak-builder` are installed:

#### Ubuntu / Debian:
```bash
sudo apt install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

#### Fedora:
```bash
sudo dnf install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

### C. Vala Linter & Quality Tooling
Install `vala-lint` to check code style against project Vala/GNOME standards:
```bash
# Via Flatpak or native package manager
io.elementary.vala-lint -d .
```

---

## 3. Recommended IDEs & Editor Extensions

* **GNOME Builder / VS Code**: Native Vala syntax highlighting, auto-completion, and integrated Meson/Flatpak build targets out of the box.
* **VS Code / VSCodium / Cursor**:
  - **Vala Language Server (`gvls`)** extension for rich code navigation and symbol lookup.
  - **Meson** extension for build target configuration.

---

## 4. Standard Build, Run, and Test Workflows (Non-CI)

### 1. Native Mode (Optional Fast Path)
Use native Meson as an acceleration path when your host satisfies repository toolchain requirements (notably GTK4 >= 4.14 and correct pkg-config visibility).

```bash
meson setup builddir --prefix=/usr --buildtype=debug -Dprofile=linux
meson compile -C builddir
GSK_RENDERER=cairo GTK_A11Y=none xvfb-run -a meson test -C builddir --verbose
```

### 2. AppImage Mode (Formal Packaging)
Use AppImage mode for formal packaging output and package-mode behavior checks.

Stable AppImage:
```bash
docker compose run --rm appimage
```
Devel AppImage:
```bash
docker compose run --rm appimage-devel
```
Cached devel AppImage rebuild (recommended for repeated packaging iterations):
```bash
docker compose run --rm appimage-devel-cached
```
Containerized Meson canary tests (not AppImage artifact tests):
```bash
docker compose run --rm meson-test
```
Build devel AppImage for embedded test runner:
```bash
docker compose run --rm appimage-devel
```
Direct devel AppImage test execution after build (recommended for repeated runs):
```bash
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests -p /McpProtocol/UC_70_10_10/InitializeHandshake
```
Direct script fallback only when Compose is unavailable:
```bash
./packaging/appimage/build-appimage.sh
./packaging/appimage/build-appimage.sh --devel
```
Output artifacts are placed in `dist/`.

### 3. Flatpak Mode (Maintained Parity with AppImage)
Note: Local developer commands in this guide use `flatpak run org.flatpak.Builder ...`, while CI currently uses `flatpak-builder ...` directly in `.github/workflows/CI.yml`. Both are valid and intentional for their respective environments.

Devel build + run + unit tests:
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

### 4. Escalation Rules
Escalate from native-only to AppImage and/or Flatpak verification whenever a change touches packaging-sensitive behavior: AppRun or packaging scripts, launch semantics, D-Bus/MCP behavior, portal/autostart paths, sandbox permissions, or install/runtime path logic.

For day-to-day validation, package-mode workflows (AppImage and Flatpak) are the primary source of truth. Native mode is optional when host compatibility is confirmed.

Targeted package-mode tests require full packaged runtime setup. Use devel AppImage embedded tests and Flatpak devel tests when validating behavior that depends on package context (for example desktop portal integration, session bus access, and sandbox-specific execution paths).

---

## 5. Runtime & Debugging Environment Variables

Jots recognizes several environment variables for diagnostic logging, appearance testing, headless automation, and sync configuration:

| Variable | Scope / Subsystem | Description & Usage |
|---|---|---|
| `G_MESSAGES_DEBUG=all` | GLib Logging | Enables verbose `debug ()` log output for all Jots components (storage, window lifecycle, MCP, D-Bus, portal events). |
| `G_DEBUG=fatal-criticals` | GLib Diagnostics | Forces immediate abort/core dump on any `GLib-CRITICAL` or `Gtk-WARNING`, ideal when running under `gdb`. |
| `FORCE_DARK=1` | Appearance / Theming | Forces dark mode palette and rich-tinted sticky note styling regardless of desktop portal settings. |
| `FORCE_LIGHT=1` | Appearance / Theming | Forces light mode palette and pastel sticky note styling regardless of desktop portal settings. |
| `GTK_THEME=<ThemeName>` | GTK4 Theming | Overrides the active GTK theme (e.g., `GTK_THEME=Adwaita:dark`). |
| `GSK_RENDERER=cairo` | GTK4 Rendering | Forces Cairo software rendering instead of Vulkan/GL (used for headless Xvfb / CI testing). |
| `GTK_A11Y=none` | GTK4 Accessibility | Disables accessibility bus lookup in headless and automated unit test environments. |
| `JOTS_GIT_COMMAND_TIMEOUT_SECONDS` | Git Backup & Sync | Overrides the default timeout (in seconds) for background Git CLI subprocess invocations. |

### Quick Examples

Run Jots with full debug output:
```bash
G_MESSAGES_DEBUG=all ./dist/Jots-devel-1.3.0-beta.3-x86_64.AppImage
```

Test dark appearance independently of desktop environment settings:
```bash
FORCE_DARK=1 ./dist/Jots-devel-1.3.0-beta.3-x86_64.AppImage
```

Debug critical warnings with GDB:
```bash
gdb -ex "set env G_DEBUG=fatal-criticals" -ex r --args ./dist/Jots-devel-1.3.0-beta.3-x86_64.AppImage
```

---

## 6. Next Steps
* **System Architecture**: Read [`docs/architecture.md`](../architecture.md) for subsystem boundaries and D-Bus interfaces.
* **Use-Case Library**: Browse [`docs/use-cases/`](../use-cases/) for behavioral test specifications.
* **Pull Request Guidelines**: Review [`docs/development/pull-request-guidelines.md`](pull-request-guidelines.md) before submitting contributions.
