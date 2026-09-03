# Domain 50: Theming, Styling, and Appearance

Theme color mapping, random color assignment, and dark mode stylesheet overrides.

---

## 50.10 Theme color mapping

### `UC-50.10.10` Color theme enum, hex color, and CSS class mapping
* **Trigger**: Note is created or user selects a color from the palette popover.
* **Pre-conditions**: `Themes` enum value passed.
* **Post-conditions**:
  * Maps each enum to its corresponding CSS class name via `to_css_class()`:
    * `BANANA`: `banana`
    * `TANGERINE`: `tangerine`
    * `PEACH`: `peach`
    * `WATERMELON`: `watermelon`
    * `BUBBLEGUM`: `bubblegum`
    * `LAVENDER`: `lavender`
    * `OCEAN`: `ocean`
    * `SEA_GLASS`: `sea_glass`
    * `MINT`: `mint`
    * `PEAR`: `pear`
    * `PEBBLE`: `pebble`
    * `GRAPHITE`: `graphite`
  * Maps each enum to its vivid picker chip hex color via `to_hex_color()`:
    * `BANANA`: `#FFB300`
    * `TANGERINE`: `#FF6D00`
    * `PEACH`: `#FF5252`
    * `WATERMELON`: `#D50000`
    * `BUBBLEGUM`: `#F50057`
    * `LAVENDER`: `#AA00FF`
    * `OCEAN`: `#2979FF`
    * `SEA_GLASS`: `#00BFA5`
    * `MINT`: `#00C853`
    * `PEAR`: `#AEEA00`
    * `PEBBLE`: `#9E9E9E`
    * `GRAPHITE`: `#546E7A`
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

---

## 50.30 Focus-Aware Minimalist Desktop Chrome

### `UC-50.30.10` Focus-aware actionbar reveal and hide transitions
* **Trigger**: Note window gains or loses desktop focus (`notify["is-active"]`).
* **Pre-conditions**: `ChromeController` active on `StickyNoteWindow`.
* **Post-conditions**:
  * When window is active (focused) or `autohide = false`, the bottom `Gtk.ActionBar` is immediately revealed (`revealed = true`).
  * When window loses focus (defocused) with `autohide = true`, the bottom action bar smoothly hides (`revealed = false`), maintaining a pure post-it note aesthetic.
  * The top header bar and note title remain permanently visible.

### `UC-50.30.20` Active popover chrome retention override
* **Trigger**: Popover menu, emoji chooser, or search popover is opened on an unfocused or hovered note.
* **Pre-conditions**: Popover active signal emitted.
* **Post-conditions**:
  * Action bar remains locked in the revealed state (`revealed = true`) for the duration of the popover session, even if the mouse pointer moves outside the note window.
  * When all popovers are closed, the action bar returns to normal focus/hover-aware visibility.

### `UC-50.30.30` Debounced hover reveal and cancellation
* **Trigger**: Mouse cursor enters or leaves the note window while unfocused.
* **Pre-conditions**: `Gtk.EventControllerMotion` attached to root view.
* **Post-conditions**:
  * Mouse entry schedules a 250ms debounce timer to prevent toolbar flickering during desktop cursor sweeps.
  * If the cursor remains hovered for $\ge 250\text{ms}$, the action bar smoothly slides into view.
  * If the cursor leaves before the 250ms delay expires, the timer is cancelled and the action bar remains hidden.

