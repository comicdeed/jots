# Domain 60: Global Actions, Settings, and System Integration

Application settings toggles, keyboard accelerators, action bar display modes, scribbly blur effects, and autostart portal integration.

---

## 60.10 Application preferences and toggles

### `UC-60.10.10` Hide bottom action bar
* **Trigger**: User toggles "Auto-hide bottom bar" in **Preferences $\rightarrow$ Appearance** or presses `Ctrl+T`.
* **Pre-conditions**: GSettings key `hidebar` updated.
* **Post-conditions**:
  * Action bar collapses and reveals only on hover or interaction when enabled.

### `UC-60.10.20` Scribble unfocused notes
* **Trigger**: User toggles "Scribble unfocused notes" in **Preferences $\rightarrow$ Appearance** or presses `Ctrl+H`.
* **Pre-conditions**: GSettings key `scribbly` updated.
* **Post-conditions**:
  * Applies the `.scribbly` font class to unfocused notes to obscure text.
  * Removes `.scribbly` when the note window gains focus.

---

## 60.20 System integration and autostart

### `UC-60.20.10` Autostart registration — Flatpak
* **Trigger**: User toggles "Show notes on log in" in **Preferences $\rightarrow$ General** while running via Flatpak.
* **Pre-conditions**: `LIBPORTAL` support enabled; `FLATPAK_ID` env var is set by the Flatpak runtime.
* **Post-conditions**: XDG Background portal registers or unregisters Jots autostart via `request_background()`.

### `UC-60.20.11` Autostart registration — AppImage
* **Trigger**: User toggles "Show notes on log in" in **Preferences $\rightarrow$ General** while running via AppImage.
* **Pre-conditions**: `LIBPORTAL` support enabled; `APPIMAGE` env var is set by the AppRun script.
* **Post-conditions**:
  * On enable: writes `~/.config/autostart/io.github.comicdeed.jots.desktop` with `Exec=<AppImage path>`.
  * On disable: removes the file.

### `UC-60.20.12` Autostart registration — Native install
* **Trigger**: User toggles "Show notes on log in" in **Preferences $\rightarrow$ General** while running as a native package.
* **Pre-conditions**: `LIBPORTAL` support enabled; neither `FLATPAK_ID` nor `APPIMAGE` env var is set.
* **Post-conditions**:
  * On enable: writes `~/.config/autostart/io.github.comicdeed.jots.desktop` with `Exec=io.github.comicdeed.jots`.
  * On disable: removes the file.

### `UC-60.20.13` Autostart state sync on startup
* **Trigger**: Application startup (before the preferences window is constructed).
* **Pre-conditions**: `LIBPORTAL` support enabled.
* **Post-conditions**: GSettings `autostart` key is corrected to match actual filesystem state, preventing toggle desync when the user manually removes the autostart file outside the app.
