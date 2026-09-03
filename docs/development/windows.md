# Building for Windows

Jots can be built for Windows environments using MSYS2 and the MinGW toolchain. 

---

## 1. Prerequisites & Environment Setup

1. Download and install [MSYS2](https://www.msys2.org/).
2. Launch the MSYS2 UCRT64 shell environment.
3. Update the package database and system packages:
   ```bash
   pacman -Syu --noconfirm
   ```
4. Navigate to the directory containing the Jots source code (MSYS2 maps host drives, e.g., `/c/Users/YourName/Desktop/jots`).

---

## 2. Installing Dependencies

Install the required compilers, build systems, and libraries:
```bash
pacman -S --noconfirm \
  meson \
  gcc \
  ninja \
  mingw-w64-x86_64-desktop-file-utils \
  mingw-w64-ucrt-x86_64-gtk4 \
  mingw-w64-ucrt-x86_64-vala \
  mingw-w64-ucrt-x86_64-nsis \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-libgee \
  mingw-w64-ucrt-x86_64-gsettings-desktop-schemas \
  mingw-w64-ucrt-x86_64-gtk-elementary-theme \
  mingw-w64-ucrt-x86_64-elementary-icon-theme
```

---

## 3. Compilation & Deployment

Run the Windows deployment script to compile the application and bundle it with its dependencies:
```bash
./packaging/windows/deploy.sh
```

This script will:
1. Configure and build the application via Meson/Ninja (skipping Linux-only dependencies like `libportal`).
2. Collect the compiled binaries and necessary DLL libraries into the `./packaging/windows/deploy` directory.
3. Generate an installer setup using NSIS.

Once completed successfully, a standalone installer `.exe` will be created. The installer is configured to run without administrative privileges.

---

## 4. Platform Limitations & Differences

Because Jots is designed primarily for Linux, the Windows build has several known limitations:
* **Static Assets**: Theme-switching icons and Pride variants are not dynamically fetched or changed; the default icon is always used.
* **Updates**: There is no built-in update mechanism. To update the application, uninstall the current version and install the new version (existing notes are preserved in user directories).
* **Startup**: The option to launch Jots at Windows system startup is set during installation and cannot be toggled in-app.
* **Startup Performance**: Launch times may be slower on Windows compared to Linux due to dynamic library loading overhead.
