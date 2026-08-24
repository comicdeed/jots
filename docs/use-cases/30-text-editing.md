# Domain 30: Text Editing and Buffer Logic

List formatting, prefix expansion on keypresses, prefix migration, and hanging indentation in `Jots.TextBuffer`.

---

## 30.10 List item prefixing and formatting

### `UC-30.10.10` Applying list prefix to line range
* **Trigger**: `TextBuffer.set_list(first_line, last_line)` is called.
* **Pre-conditions**: Buffer contains lines of text, active `list_item_prefix` is set (e.g. `"- "`).
* **Post-conditions**:
  * Applies prefix at column zero to any un-prefixed lines in the range.
  * Applies the `list_item` tag to configure hanging indentation.

### `UC-30.10.20` Removing list prefix from line range
* **Trigger**: `TextBuffer.remove_list(first_line, last_line)` is called.
* **Pre-conditions**: Lines in range have list prefixes.
* **Post-conditions**:
  * Removes prefix characters from the start of each line.
  * Removes `list_item` tag from each line in the range.

### `UC-30.10.30` Detecting list state
* **Trigger**: `TextBuffer.is_list(first_line, last_line)` is called.
* **Pre-conditions**: Buffer contains lines of text.
* **Post-conditions**:
  * Returns `true` if every line in the range starts with `list_item_prefix`; returns `false` otherwise.

### `UC-30.10.40` Migrating prefix types across a note
* **Trigger**: User changes the preferred list prefix in settings (e.g. from `"- "` to `"* "` or `"1. "`).
* **Pre-conditions**: Note contains lines formatted with the old prefix.
* **Post-conditions**:
  * Finds all lines matching the old prefix and replaces them with the new prefix, preserving remaining line content.

---

## 30.20 Keyboard interactions

### `UC-30.20.10` Auto-expanding list on Enter
* **Trigger**: User presses `Enter` on a line that has a list prefix.
* **Pre-conditions**: Caret is on a bulleted line containing text after the prefix.
* **Post-conditions**:
  * Creates a new line with the current `list_item_prefix` automatically inserted.
  * Positions caret after the inserted prefix.

### `UC-30.20.20` Exiting list mode on Backspace
* **Trigger**: User presses `Backspace` on a line containing only the list prefix.
* **Pre-conditions**: Caret is positioned immediately after the prefix on an otherwise empty line.
* **Post-conditions**:
  * Deletes prefix and removes the `list_item` tag.
  * Converts line to plain text without deleting the preceding line.

---

## 30.30 Indentation and layout

### `UC-30.30.10` Hanging indent calculation
* **Trigger**: Font zoom level or prefix width changes.
* **Pre-conditions**: Prefix pixel width measured via Pango layout.
* **Post-conditions**:
  * Updates `list_item` tag's `indent` to `-indent_width`, ensuring wrapped lines align with text rather than the bullet prefix.

### `UC-30.30.20` Restoring indentation after undo or redo
* **Trigger**: User triggers undo (`Ctrl+Z`) or redo (`Ctrl+Shift+Z`).
* **Pre-conditions**: Buffer state reverts.
* **Post-conditions**:
  * Rescans lines and re-applies `list_item` tags to all bulleted lines via `restore_list_item_indentation()`.
