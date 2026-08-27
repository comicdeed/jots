# Building & Running Jots

This document describes how to compile, install, and run Jots on Linux systems. 

> 💡 **Developer Setup**: For complete repository cloning, Git guardrails configuration, and IDE tooling setup, see the **[Developer Setup Guide](setup.md)**.

---

## 1. Building via Flatpak (Recommended)

Flatpak is the recommended compilation and deployment method for Jots as it automatically pulls all elementary OS and GNOME runtime dependencies inside a sandbox.

### Prerequisites
Make sure you have `flatpak` and `flatpak-builder` installed on your host system:
```bash
sudo apt install flatpak flatpak-builder
# Or via your system's package manager
```
Ensure you have the Flathub remote enabled:
```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

### Build Targets

Depending on your target environment, build Jots using one of the manifests below:

#### A. Development Version (Recommended for testing)
Uses the Flathub runtime and GNOME SDK:
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir io.github.comicdeed.jots.devel.yml
```
Run the development build:
```bash
flatpak run io.github.comicdeed.jots.devel
```

#### B. Stable Flathub Release
Builds the standard production release using Flathub dependencies:
```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache builddir io.github.comicdeed.jots.yml
```
Run the stable Flathub build:
```bash
flatpak run io.github.comicdeed.jots
```

---

## 2. Native Compilation (Local Build)

If you prefer to compile Jots natively on your host system, install the development dependencies and build using Meson.

### Native Dependencies
* `libgtk-4-dev`
* `libgee-0.8-dev`
* `libjson-glib-dev`
* `libportal-gtk4-dev`
* `librsvg2-dev`
* `meson`
* `valac`

#### Debian/Ubuntu/elementary OS
```bash
sudo apt install libjson-glib-1.0-0 libgee-0.8-2 meson libvala-0.56-0 libportal-gtk4-dev
```

#### Fedora
```bash
sudo dnf install json-glib-devel libgee-devel meson libvala libportal-devel
```

### Meson Setup & Build
1. Configure the build environment:
   ```bash
   meson setup builddir --prefix=/usr
   ```
2. Compile the source code:
   ```bash
   meson compile -C builddir
   ```
3. Update translation files:
   ```bash
   meson compile -C builddir jots-pot
   meson compile -C builddir jots-update-po
   ```

### Installing and Running
To install natively:
```bash
sudo meson install -C builddir
```
To uninstall:
```bash
sudo meson compile --clean -C builddir
```
