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

### `UC-30.20.110` Read-only / lock mode mutation guardrails
* **Trigger**: User attempts programmatic modifications (list continuation on `Enter`, paste shortcuts, emoji insertion) when `is_readonly = true`.
* **Pre-conditions**: Note window is locked (`editable = false`).
* **Post-conditions**:
  * All buffer insertion and deletion operations are blocked.
  * Buffer content remains unchanged.

### `UC-30.20.120` Interactive checklist click and keyboard toggle
* **Trigger**: User clicks directly on a checklist checkbox (`- [ ]` / `- [x]`) or presses `Ctrl + D` / `Ctrl + Enter`.
* **Pre-conditions**: Note is editable (`editable = true`).
* **Post-conditions**:
  * On click on `[ ]` or `[x]`, flips state atomically (`[ ]` $\leftrightarrow$ `[x]`) and re-highlights Markdown.
  * On keyboard shortcut (`Ctrl + D` / `Ctrl + Enter`), toggles checklist item on the active line or converts plain text/bullets to `- [ ]`.
  * Preserves user undo history in a single atomic action.


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

---

## 30.40 Resilient clipboard and smart paste

### `UC-30.40.10` Unicode bullet and task normalization
* **Trigger**: User presses `Ctrl+V` to paste text containing non-standard bullet characters (`•`, `◦`, `▪`, etc.) or loose checkbox notations (`[X]`, `[v]`, `☐`, `☑`, `✅`).
* **Pre-conditions**: Caret is in standard Markdown text outside of code fences or inline backticks.
* **Post-conditions**:
  * Normalizes bullet characters to `- ` and tasks to `- [ ] ` or `- [x] `.
  * Emits `paste_normalized` signal displaying a transient toast feedback banner.
  * Wraps insertion in an atomic user action so a single `Ctrl+Z` undo reverts the paste completely.

### `UC-30.40.20` Code block paste protection
* **Trigger**: User presses `Ctrl+V` with the caret inside a code block (`TAG_CODE_BLOCK`, `TAG_CODE`, or active backtick fence).
* **Pre-conditions**: Caret is within code context.
* **Post-conditions**:
  * Bypasses all Markdown normalizations and HTML transformations.
  * Pastes literal clipboard text directly into the buffer.
  * Suppresses toast feedback.

### `UC-30.40.30` Raw paste bypass (Ctrl+Shift+V)
* **Trigger**: User presses `Ctrl+Shift+V` or selects "Paste Without Formatting" from the context menu.
* **Pre-conditions**: Clipboard contains text.
* **Post-conditions**:
  * Pastes raw literal text directly without running `MarkdownNormalizer` or `HtmlToMarkdown`.
  * Suppresses toast feedback.

### `UC-30.40.40` Rich text and HTML conversion
* **Trigger**: User presses `Ctrl+V` to paste content copied from a web browser, word processor, or rich-text source.
* **Pre-conditions**: Clipboard contains `text/html` payload and caret is outside of code context.
* **Post-conditions**:
  * Converts HTML structure (headings, formatting, links, lists, code spans, tables, blockquotes) to standard Markdown.
  * Sanitizes `<style>`, `<script>`, comments, and non-formatting markup.
  * Displays transient feedback toast informing the user that rich text was converted with `Ctrl+Shift+V` bypass available.

