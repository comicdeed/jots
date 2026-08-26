# Domain 50: Theming, Styling, and Appearance

Theme color mapping, random color assignment, and dark mode stylesheet overrides.

---

## 50.10 Theme color mapping

### `UC-50.10.10` Color theme enum, hex color, and CSS class mapping
* **Trigger**: Note is created or user selects a color from the palette popover.
* **Pre-conditions**: `Themes` enum value passed.
* **Post-conditions**:
  * Maps each enum to its corresponding CSS class name via `to_css_class()`:
    * `BLUEBERRY`: `blueberry`
    * `MINT`: `mint`
    * `LIME`: `lime`
    * `BANANA`: `banana`
    * `ORANGE`: `orange`
    * `STRAWBERRY`: `strawberry`
    * `BUBBLEGUM`: `bubblegum`
    * `GRAPE`: `grape`
    * `COCOA`: `cocoa`
    * `SLATE`: `slate`
    * `LATTE`: `latte` (development builds)
  * Maps each enum to its canonical 500-shade hex color via `to_hex_color()`:
    * `BLUEBERRY`: `#4285f4`
    * `MINT`: `#2ecc71`
    * `LIME`: `#87d322`
    * `BANANA`: `#f6d32d`
    * `ORANGE`: `#ff7800`
    * `STRAWBERRY`: `#ed333b`
    * `BUBBLEGUM`: `#e0569a`
    * `GRAPE`: `#9141ac`
    * `COCOA`: `#865e3c`
    * `SLATE`: `#606f7b`
    * `LATTE`: `#bfa07a`
  * Renders discrete circular color pills with matching outer selection rings in `ColorBox` via direct Cairo drawing.
  * Returns localized display name via `to_nicename()`.

### `UC-50.10.20` Random theme selection
* **Trigger**: Creating a new note without an explicit color argument.
* **Pre-conditions**: Optional `Themes last_theme` supplied.
* **Post-conditions**:
  * Generates a random theme that differs from `last_theme`.

---

## 50.20 Dark mode theming and overrides

### `UC-50.20.10` System dark mode synchronization
* **Trigger**: Desktop color scheme setting changes between light and dark.
* **Pre-conditions**: `Gtk.Settings.gtk_application_prefer_dark_theme` or `org.freedesktop.portal.Settings` emits change signal.
* **Post-conditions**:
  * Synchronizes `.dark` CSS class on `StickyNoteWindow` instances.
  * Adjusts background and text CSS variables to dark palette values.

### `UC-50.20.30` Environment theme overrides
* **Trigger**: Application starts with `FORCE_DARK=1` or `FORCE_LIGHT=1` set.
* **Pre-conditions**: Process environment inspected at startup.
* **Post-conditions**:
  * `FORCE_DARK=1`: Applies dark mode styling regardless of system setting.
  * `FORCE_LIGHT=1`: Applies light mode styling regardless of system setting.
