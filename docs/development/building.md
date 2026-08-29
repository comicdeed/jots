# Building & Running Jots

This document describes how to compile, package, test, and run Jots on Linux systems.

> 💡 **Developer Setup**: For complete repository cloning, Git guardrails configuration, and IDE tooling setup, see the **[Developer Setup Guide](setup.md)**.

---

## 1. Packaging Workflows (Non-CI)

For day-to-day work, AppImage is the primary packaging path. Flatpak is actively maintained for parity. Native builds are an optional acceleration path when host toolchain compatibility is satisfied.

1. **Primary path: AppImage via Docker Compose (default, repeatable)**
2. **Maintained parallel path: Flatpak devel build + Flatpak devel unit tests**
3. **Optional acceleration path: Native Meson host build**
4. **Additional path: Windows installer build (MSYS2)**

### A. AppImage via Docker Compose (Default)
Stable AppImage:
```bash
docker compose run --rm appimage
```
Devel AppImage:
```bash
docker compose run --rm appimage-devel
```
Cached devel AppImage rebuild (faster repeat packaging):
```bash
docker compose run --rm appimage-devel-cached
```
Containerized Meson canary tests (not AppImage artifact tests):
```bash
docker compose run --rm meson-test
```
Build devel AppImage for targeted package-mode tests:
```bash
docker compose run --rm appimage-devel
```
After building the devel artifact, run tests directly for faster iteration and selector support:
```bash
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests
./dist/Jots-devel-<version>-<arch>.AppImage --unit-tests -p /McpProtocol/UC_70_10_10/InitializeHandshake
```
Fallback only when Compose is unavailable:
```bash
./packaging/appimage/build-appimage.sh
./packaging/appimage/build-appimage.sh --devel
```

Generated artifacts are written to `dist/`.

Targeted AppImage package-mode tests must be run in the full packaged runtime. They validate packaging-context behavior that native test runs do not fully cover.

## 2. Building via Flatpak

Flatpak is the recommended sandboxed runtime validation path for Jots because it automatically pulls the expected GNOME platform dependencies inside an isolated environment.

Note: This document uses `flatpak run org.flatpak.Builder ...` for local workflows. CI uses `flatpak-builder ...` directly in `.github/workflows/CI.yml`; both approaches are valid.

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
Run Flatpak devel unit tests:
```bash
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
```
Direct Flatpak devel test reruns with selectors:
```bash
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel -p /McpProtocol/UC_70_10_10/InitializeHandshake
```
These tests should be used for targeted package-mode verification when behavior depends on Flatpak sandbox/portal/session integration.

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

## 3. Native Compilation (Local Build)

Use this path when your host toolchain matches repository requirements (including GTK4 >= 4.14).

### Native Dependencies
* `libgtk-4-dev`
* `libgee-0.8-dev`
* `libjson-glib-dev`
* `libportal-gtk4-dev`
* `librsvg2-dev`
* `meson`
* `valac`

#### Debian/Ubuntu
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

## 4. Windows Packaging (Experimental)

For local Windows installer packaging, follow the dedicated guide:

* [Windows Build Guide](windows.md)
