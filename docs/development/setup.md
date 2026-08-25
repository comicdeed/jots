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

### A. Flatpak Sandbox Environment (Recommended)
Flatpak is the standard development and debugging environment for Jots. Ensure `flatpak` and `flatpak-builder` are installed:

#### Ubuntu / Debian / elementary OS:
```bash
sudo apt install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

#### Fedora:
```bash
sudo dnf install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

### B. Vala Linter & Quality Tooling
Install `vala-lint` to check code style against elementary / GNOME standards:
```bash
# Via Flatpak or native package manager
io.elementary.vala-lint -d .
```

---

## 3. Recommended IDEs & Editor Extensions

* **GNOME Builder / elementary Code**: Native Vala syntax highlighting, auto-completion, and integrated Meson/Flatpak build targets out of the box.
* **VS Code / VSCodium / Cursor**:
  - **Vala Language Server (`gvls`)** extension for rich code navigation and symbol lookup.
  - **Meson** extension for build target configuration.

---

## 4. Quick Build & Verification Workflows

### 1. Build Development Flatpak
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir io.github.comicdeed.jots.devel.yml
```

### 2. Run Jots Locally
```bash
flatpak run io.github.comicdeed.jots.devel
```

### 3. Run Automated Canary Unit Tests
```bash
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
```

### 4. Test Native MCP Server over stdio
```bash
flatpak run --command=jots-mcp io.github.comicdeed.jots.devel
```

---

## 5. Next Steps
* **System Architecture**: Read [`docs/architecture.md`](../architecture.md) for subsystem boundaries and D-Bus interfaces.
* **Use-Case Library**: Browse [`docs/use-cases/`](../use-cases/) for behavioral test specifications.
* **Pull Request Guidelines**: Review [`docs/development/pull-request-guidelines.md`](pull-request-guidelines.md) before submitting contributions.
