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

### C. Snap and AppImage
* **Status**: Unofficial (community contributions welcome).
* When packaging for Snap or AppImage, ensure the GSettings schemas and desktop file actions (`New Note`) map correctly to the runtime confinement.
