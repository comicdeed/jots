# Alternative Packaging Formats & Operating Systems

This document outlines the current support status and considerations for packaging Jots across different distribution formats and platforms.

---

## 1. Snap & AppImage
* **Status**: There are currently no official Snap or AppImage packages maintained.
* **Considerations**: If you are interested in creating or maintaining a Snapcraft or AppImage packaging configuration for Jots, contributions are welcome.

---

## 2. Native Distribution Packages (DEB / RPM)
If packaging Jots natively for a Linux distribution (such as Debian, Ubuntu, Fedora, or Arch), please note:
* **Storage Directory**: Jots assumes it runs within a sandbox environment (like Flatpak) by default. Native packages may need to adjust the data directory paths or configurations to align with standard filesystem hierarchies (FHS).
* **Dependency Plumbings**: Check the `meson.build` build configuration to ensure that dependencies (such as `libportal`) compile and link correctly against system libraries.

---

## 3. macOS Support
* **Status**: Experimental.
* **Hurdles**: 
  * DBus messaging is not natively supported on macOS.
  * Integration helpers (`libportal`) are not available on macOS.
  * GTK4 CSS styling and rendering issues may exist.
