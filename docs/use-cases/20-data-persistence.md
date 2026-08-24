# Domain 20: Data Persistence and Migration

JSON serialization of `NoteData`, disk I/O handling in `Storage`, legacy state migration, and auto-save debouncing.

---

## 20.10 Model serialization

### `UC-20.10.10` Full JSON round-trip serialization
* **Trigger**: Packaging note state to JSON and restoring from JSON.
* **Pre-conditions**: Valid `NoteData` instance with title, content, theme, monospace, zoom, width, and height.
* **Post-conditions**:
  * Serializes all seven fields into a `Json.Object` via `to_json()`.
  * Restores identical values for all seven properties via `from_json()`.

### `UC-20.10.20` Corrupted or missing field fallbacks
* **Trigger**: Parsing a `Json.Object` with missing, partial, or malformed fields.
* **Pre-conditions**: Storage JSON object has missing keys.
* **Post-conditions**:
  * Missing `title` falls back to default fallback text.
  * Missing `color` falls back to a valid random `Themes` enum value.
  * Missing `content` falls back to an empty string.
  * Missing `monospace` falls back to `DEFAULT_MONO` (`false`).
  * Missing `zoom` falls back to `DEFAULT_ZOOM` (`100`).
  * Missing `width` and `height` fall back to `DEFAULT_WIDTH` (`290`) and `DEFAULT_HEIGHT` (`320`).
  * No exceptions or crashes occur.

### `UC-20.10.30` Zoom value clamping
* **Trigger**: Parsing JSON with out-of-bound zoom values.
* **Pre-conditions**: `zoom < ZOOM_MIN (20)` or `zoom > ZOOM_MAX (300)`.
* **Post-conditions**:
  * Clamps `zoom` to `ZOOM_MIN` or `ZOOM_MAX` respectively.

---

## 20.20 Storage disk I/O

### `UC-20.20.10` Writing note array to disk
* **Trigger**: `Storage.save(Json.Array)` is called.
* **Pre-conditions**: Valid JSON array passed.
* **Post-conditions**:
  * Ensures data directory `~/.local/share/io.github.comicdeed.jots/` exists.
  * Writes `saved_state.json` atomically with the serialized array.

### `UC-20.20.20` Loading note array from disk
* **Trigger**: `Storage.load()` is called.
* **Pre-conditions**: Storage file exists.
* **Post-conditions**:
  * Reads and parses `saved_state.json` into a `Json.Array`.
  * If the file does not exist, returns an empty `Json.Array` without error.

### `UC-20.20.40` Legacy storage directory migration
* **Trigger**: Application starts up and detects un-namespaced storage at `~/.local/share/saved_state.json`.
* **Pre-conditions**: Legacy file exists, target namespaced directory has no state.
* **Post-conditions**:
  * Moves legacy file to `~/.local/share/io.github.comicdeed.jots/saved_state.json`.

---

## 20.30 Debounced auto-saving

### `UC-20.30.10` Keystroke debouncing
* **Trigger**: User types characters into title or text editor in rapid succession.
* **Pre-conditions**: Keystrokes occur within the `DEBOUNCE (900ms)` window.
* **Post-conditions**:
  * Cancels and reschedules the existing timeout source.
  * Writes to disk only after 900ms of idle time.

### `UC-20.30.20` Debounce expiry commit
* **Trigger**: 900ms elapses after the last keystroke.
* **Pre-conditions**: Pending changes registered in `NoteManager`.
* **Post-conditions**:
  * Queries all open notes and writes updated array to storage via `NoteManager.immediately_save()`.

### `UC-20.30.30` Explicit save flush
* **Trigger**: User presses `Ctrl+S`.
* **Pre-conditions**: Open note is active.
* **Post-conditions**:
  * Cancels any active debounce timer and immediately commits all notes to disk.
