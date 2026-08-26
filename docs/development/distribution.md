# Distribution and Packaging Guide

Technical guidelines, dependency requirements, and architectural considerations for downstream package maintainers and platform porters.

---

## 1. Primary target and packaging philosophy

Jots is developed primarily as a sandboxed Flatpak application targeting modern Linux desktop environments (such as elementary OS and GNOME). Downstream maintainers packaging Jots for native distributions (e.g. Debian, Arch, Fedora, openSUSE) or alternative platforms should review the integration requirements below.

---

## 2. Dependencies and build configuration

Jots uses the Meson build system and Vala compiler.

### Core build dependencies
* `glib-2.0`, `gobject-2.0`, `gio-2.0` (>= 2.74)
* `gtk4` (>= 4.10)
* `granite-7` (>= 7.0.0)
* `json-glib-1.0` (>= 1.6)
* `libportal`, `libportal-gtk4` (optional portal integrations for sandbox autostart)

### Build options (`meson_options.txt`)
* `profile`: Set to `'default'` for standard stable releases, or `'development'` to enable debug logging, development styling classes, and parallel installation alongside the stable release.

---

## 3. Downstream distribution packaging guidelines

When creating native distribution packages (`.deb`, `.rpm`, `.pkg.tar.zst`):

### A. State storage and filesystem hierarchy
* In sandbox environments (Flatpak), note state is persisted automatically under `XDG_DATA_HOME/io.github.comicdeed.jots/saved_state.json`.
* In native packaging, ensure user data directories adhere to the XDG Base Directory specification. Note state is read and saved at `Environment.get_user_data_dir() + "/io.github.comicdeed.jots/saved_state.json"`.

### B. Bundled fonts and resources
* Jots embeds custom stylesheet overrides and scribble fonts inside GResource bundles compiled directly into the binary.
* Packaging scripts must execute `glib-compile-schemas` for the GSettings schema (`io.github.comicdeed.jots.gschema.xml`) during post-installation hooks.

### C. Icon variants
* Production builds install the default icon suite from `data/icons/default/` into `/usr/share/icons/hicolor/`.
* The development icon variant is installed automatically when passing `-Dprofile=development` to Meson.

---

## 4. Platform porting and operating system status

### A. Windows (MSYS2 / MinGW)
* **Status**: Supported via experimental builds.
* **Build guide**: See [`docs/development/windows.md`](windows.md) for compilation instructions.
* **Adaptations**: Portal autostart and Linux-specific DBus dependencies are conditionally disabled under Windows targets.

### B. macOS
* **Status**: Community experimental (unmaintained).
* **Technical considerations**:
  * DBus messaging and `libportal` are Linux-specific and must be excluded or stubbed out.
  * GTK 4 backend rendering on macOS Quartz requires native window decorations and key accelerator adjustments.

### C. AppImage Packaging
* **Status**: Official release target (`packaging/appimage/`).
* **Tooling**: Built via `linuxdeploy` + `linuxdeploy-plugin-gtk` with a custom dual-entrypoint `AppRun` script.
* **Dual-Entrypoint**: Normal execution launches the GTK4 GUI (`io.github.comicdeed.jots`); passing `--mcp` or executing as `jots-mcp` launches the headless AI Model Context Protocol server over `stdio`.
* **Child Process Isolation**: The `AppRun` wrapper isolates `LD_LIBRARY_PATH` and `XDG_DATA_DIRS` to prevent library pollution into external helper applications (such as web browsers or mail clients spawned via `Ctrl + Click`).

---

## 5. Direct Release Pipeline (GitHub Releases)

Jots uses a **Compile Once, Package Many** automated GitHub Actions matrix (`.github/workflows/release.yml`) triggered automatically when merging a `release/*` PR into `main` (or on manual dispatch / pushed tags). See the complete [Release Workflow & Automation Guide](release-workflow.md).

| Artifact | Target Audience / Format | Key Characteristics |
| :--- | :--- | :--- |
| **`Jots-<version>-<arch>.AppImage`** | Linux (Portable Click-and-Run) | Self-contained single-file executable for Ubuntu, Debian, Fedora, Arch, elementary OS. |
| **`io.github.comicdeed.jots-<version>.flatpak`** | Linux (Flatpak Standalone) | Single-file Flatpak bundle installable via `flatpak install io.github.comicdeed.jots-<version>.flatpak`. |
| **`Jots-<version>-Installer.exe`** | Windows (x86_64) | Standalone NSIS installer built with MSYS2. |
| **`SHA256SUMS.txt`** | Integrity Checksums | Cryptographic checksums for all release assets. |

---

## 6. AppCenter & Downstream Repositories

Flathub distributes Jots across two official channels:

| Channel | Remote / Repository | Flathub Repository Branch | Allowed Release Types | User Installation Command |
| :--- | :--- | :--- | :--- | :--- |
| **Stable** | `flathub` | `master` on `flathub/io.github.comicdeed.jots` | Standard releases (`1.0.0`, `1.1.0`) | `flatpak install flathub io.github.comicdeed.jots` |
| **Beta** | `flathub-beta` | `beta` on `flathub/io.github.comicdeed.jots` | Development pre-releases (`1.1.0-beta.1`) | `flatpak install flathub-beta io.github.comicdeed.jots` |

### A. Initial Flathub Onboarding PR
* New application submissions to `flathub/flathub` initialize the application's primary **Stable channel** (`master` branch).
* Flathub's automated submission linter (`flatpak-builder-lint`) requires the initial release in AppStream metadata (`data/jots.metainfo.xml.in.in`) to be a standard stable tag (`1.0.0`), preventing unversioned or prerelease-only store listings.

### B. Distributing Future Beta Releases
1. In `jots` upstream, bump version to `X.Y.Z-beta.N` in `meson.build` and add `<release version="X.Y.Z-beta.N" type="development" date="YYYY-MM-DD">` to `data/jots.metainfo.xml.in.in`.
2. Tag `X.Y.Z-beta.N` and push to GitHub.
3. Update `io.github.comicdeed.jots.yml` with the archive URL and computed SHA256 checksum, and push to the **`beta` branch** of `flathub/io.github.comicdeed.jots`.
4. Flathub builds and publishes to the `flathub-beta` remote.

### C. Distributing Future Stable Releases
1. In `jots` upstream, finalize version `X.Y.Z` in `meson.build` and `<release version="X.Y.Z" date="YYYY-MM-DD">` in `data/jots.metainfo.xml.in.in`.
2. Tag `X.Y.Z` on `main` and push.
3. Update `io.github.comicdeed.jots.yml` on the **`master` branch** of `flathub/io.github.comicdeed.jots` to publish to the global Flathub stable repository.

