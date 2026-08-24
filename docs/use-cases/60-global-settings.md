# Domain 60: Global Actions, Settings, and System Integration

Application settings toggles, keyboard accelerators, action bar display modes, scribbly blur effects, and autostart portal integration.

---

## 60.10 Application preferences and toggles

### `UC-60.10.10` Hide bottom action bar
* **Trigger**: User toggles "Hide bottom bar" in Preferences or presses `Ctrl+T`.
* **Pre-conditions**: GSettings key `hidebar` updated.
* **Post-conditions**:
  * Action bar collapses and reveals only on hover or interaction when enabled.

### `UC-60.10.20` Scribble unfocused notes
* **Trigger**: User toggles "Scribble unfocused notes" in Preferences or presses `Ctrl+H`.
* **Pre-conditions**: GSettings key `scribbly` updated.
* **Post-conditions**:
  * Applies the `.scribbly` font class to unfocused notes to obscure text.
  * Removes `.scribbly` when the note window gains focus.

---

## 60.20 System integration and autostart

### `UC-60.20.10` Autostart portal registration
* **Trigger**: User toggles "Show notes on log in" in Preferences.
* **Pre-conditions**: `LIBPORTAL` support enabled.
* **Post-conditions**:
  * Requests the XDG background portal to register or unregister Jots at user session startup.
