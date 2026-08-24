# Domain 10: Note Lifecycle and Window Management

Note window creation, deletion, undo restoration, geometry tracking, and application lifecycle termination.

---

## 10.10 Window creation and spawning

### `UC-10.10.10` Standard note creation via action
* **Trigger**: User presses `Ctrl+N` or activates the new note button on an active note's action bar.
* **Pre-conditions**: Application is running.
* **Post-conditions**:
  * Creates a new `NoteData` instance with standard dimensions (`DEFAULT_WIDTH = 290`, `DEFAULT_HEIGHT = 320`).
  * Assigns a random title and random theme.
  * Instantiates a `StickyNoteWindow`, registers it in `NoteManager.open_notes`, and presents the window.
  * Triggers debounced save to record the new note in storage.

### `UC-10.10.20` First-run fallback creation
* **Trigger**: Application starts up and `Storage.content` returns an empty array.
* **Pre-conditions**: First launch or user previously closed all notes.
* **Post-conditions**:
  * Creates a default note set to `Themes.BLUEBERRY` with an empty title and standard dimensions.
  * Presents the window on screen.

### `UC-10.10.30` Session restoration on startup
* **Trigger**: Application launches with existing serialized notes in storage.
* **Pre-conditions**: Storage file contains one or more serialized note objects.
* **Post-conditions**:
  * Deserializes each JSON object via `NoteData.from_json()`.
  * Spawns a `StickyNoteWindow` for each record with restored dimensions, position, theme, and text.

---

## 10.20 Window deletion and undo recovery

### `UC-10.20.10` Deleting a note window
* **Trigger**: User presses `Ctrl+W` or clicks the delete icon in the action bar.
* **Pre-conditions**: Note window is active and focused.
* **Post-conditions**:
  * Packages note state via `StickyNoteWindow.packaged()` and caches it into `NoteManager.last_deleted`.
  * Enables the `Application.ACTION_RESTORE_LAST` action.
  * Removes window from `open_notes` registry and destroys the widget.
  * Immediately saves remaining open notes to disk via `immediately_save()`.

### `UC-10.20.20` Restoring last deleted note
* **Trigger**: User presses `Ctrl+R` or activates "Restore note" in Preferences.
* **Pre-conditions**: `last_deleted` is non-null and `ACTION_RESTORE_LAST` is enabled.
* **Post-conditions**:
  * Spawns a new note window populated with the cached `last_deleted` properties.
  * Disables the `ACTION_RESTORE_LAST` action.
  * Updates storage immediately.

### `UC-10.20.30` Disabled restore state
* **Trigger**: User presses `Ctrl+R` when no notes have been deleted in the current session.
* **Pre-conditions**: `ACTION_RESTORE_LAST` is disabled.
* **Post-conditions**:
  * Ignores keystroke without error.

---

## 10.30 Window state packing and geometry

### `UC-10.30.10` Packaging window geometry on save
* **Trigger**: Save timer expires or window closes.
* **Pre-conditions**: Active `StickyNoteWindow` exists.
* **Post-conditions**:
  * Reads current window width, height, title, content, theme, zoom, and monospace toggle into a `NoteData` instance.

### `UC-10.30.20` Application termination on closing all notes
* **Trigger**: User closes the last open sticky note.
* **Pre-conditions**: `open_notes.size == 0`.
* **Post-conditions**:
  * If Preferences window is open, application remains running.
  * If Preferences window is closed, application exits cleanly via `quit()`.
