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

---

## 20.40 Markdown file persistence & YAML headers

### `UC-20.40.10` Markdown round-trip serialization
* **Trigger**: Note is saved to disk as an individual `.md` file.
* **Pre-conditions**: Valid `NoteData` instance.
* **Post-conditions**:
  * Formats YAML front-matter header with `id`, `title`, `theme`, `monospace`, `zoom`, `width`, `height`.
  * Appends note body text directly below the YAML front-matter block.
  * Correctly deserializes all metadata and body text when re-opened.

### `UC-20.40.20` Fallback on missing or invalid YAML front-matter
* **Trigger**: Loading a raw `.md` file without YAML headers (e.g. created by external editor).
* **Pre-conditions**: Markdown file exists without `---` delimiters.
* **Post-conditions**:
  * Treats the entire file as note body content.
  * Generates a stable UUID and falls back to default window dimensions and pastel theme without errors.

---

## 20.50 Non-destructive Jorts Migration Helper

### `UC-20.50.10` Legacy candidate discovery
* **Trigger**: Application starts up or user clicks "Import Notes" in **Preferences $\rightarrow$ General**.
* **Pre-conditions**: System contains existing Jorts installations (`~/.local/share/io.github.elly_code.jorts/` or Flatpak `~/.var/app/io.github.elly_code.jorts/`).
* **Post-conditions**:
  * Scans candidate locations in priority order and returns existing `saved_state.json` paths.

### `UC-20.50.20` Non-destructive import
* **Trigger**: User accepts the first-run migration dialog or triggers import.
* **Pre-conditions**: Valid legacy Jorts `saved_state.json` file.
* **Post-conditions**:
  * Reads and converts legacy notes into individual `.md` files in Jots storage.
  * Never deletes, moves, or mutates the original Jorts `saved_state.json` file.

### `UC-20.50.30` Duplicate note protection
* **Trigger**: Migration is triggered when notes with identical IDs already exist in Jots.
* **Pre-conditions**: Some legacy note IDs match existing Jots note IDs.
* **Post-conditions**:
  * Skips duplicate IDs and preserves the user's current Jots notes without overwriting.

### `UC-20.50.40` Malformed JSON safety
* **Trigger**: Legacy `saved_state.json` is corrupted or truncated.
* **Pre-conditions**: Invalid JSON syntax on disk.
* **Post-conditions**:
  * Logs a non-fatal warning and safely returns an empty candidate list without crashing.

