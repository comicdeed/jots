# Domain 40: Hyperlink and Rich Content

Link and email pattern detection, Unicode character offset tracking, incremental scanning, and interaction handlers in `Granite.HyperTextView`.

---

## 40.10 Pattern detection

### `UC-40.10.10` Web URL detection
* **Trigger**: Text containing `http://` or `https://` URLs is inserted or pasted into the buffer.
* **Pre-conditions**: Text matches URL pattern.
* **Post-conditions**:
  * Applies a `Gtk.TextTag` with single underline over the matched range.
  * Stores the full URI string in tag data.

### `UC-40.10.20` Email address detection
* **Trigger**: Text containing email address (`user@domain.tld`) is present in the buffer.
* **Pre-conditions**: Text matches email pattern without scheme.
* **Post-conditions**:
  * Applies a tag storing the URI prefixed with `mailto:` (e.g. `mailto:user@domain.tld`).

### `UC-40.10.30` Multibyte and Unicode offset calculation
* **Trigger**: URLs positioned adjacent to multibyte characters (emojis, accents, CJK glyphs).
* **Pre-conditions**: Buffer contains UTF-8 characters where byte count differs from character count.
* **Post-conditions**:
  * Calculates start and end positions using character offsets rather than byte indexes, preventing tag misalignment.

---

## 40.20 Incremental scanning and debouncing

### `UC-40.20.10` Debounced scan execution
* **Trigger**: Buffer text changes during user typing.
* **Pre-conditions**: User enters characters into the editor.
* **Post-conditions**:
  * Delays rescan by 300ms. Subsequent keystrokes within 300ms reset the timer.

### `UC-40.20.20` Range-limited incremental scan
* **Trigger**: Editing occurs within a specific line or paragraph.
* **Pre-conditions**: Buffer tracks modified offset range.
* **Post-conditions**:
  * Rescans only lines encompassing the modified range.
  * Prunes and re-applies tags only within that range.

### `UC-40.20.30` Full rescan on paste
* **Trigger**: User pastes content into the buffer.
* **Pre-conditions**: Clipboard paste operation completes.
* **Post-conditions**:
  * Rescans the entire buffer to detect all newly inserted links.

---

## 40.30 Link interaction and mouse pointer

### `UC-40.30.10` Mouse hover and modifier handling
* **Trigger**: User moves mouse cursor over a tagged URL.
* **Pre-conditions**: Cursor hovers over text possessing a URI tag.
* **Post-conditions**:
  * If `Ctrl` is not pressed: cursor remains standard text caret and tooltip displays "Follow Link (Control + Click)".
  * If `Ctrl` is pressed: cursor switches to pointer hand icon.

### `UC-40.30.20` Activating a link
* **Trigger**: User clicks a tagged URL while holding `Ctrl`.
* **Pre-conditions**: `Ctrl` key is pressed and click location contains a URI tag.
* **Post-conditions**:
  * Launches the URI via `Gtk.show_uri()`.
  * Unmodified clicks do not launch the URI and instead move the text caret.
