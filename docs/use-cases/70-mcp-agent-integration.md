# Domain 70: Model Context Protocol (MCP) and External Automation

Model Context Protocol (MCP) JSON-RPC tooling, D-Bus session bus IPC, note synchronization, resources, prompts, and defensive guardrails.

---

## 70.10 Note querying and reading

### `UC-70.10.10` List active desktop notes
* **Trigger**: External AI client calls MCP tool `list_notes()`.
* **Pre-conditions**: Jots application is running and registered on D-Bus session bus.
* **Post-conditions**:
  * Jots returns a serialized JSON array containing all active note summaries (`id`, `title`, `theme`, `content_length`, `monospace`).
  * No modification to note state or disk storage occurs.

### `UC-70.10.20` Read individual note detail
* **Trigger**: External AI client calls MCP tool `read_note(id: <UUID>)`.
* **Pre-conditions**: Target note UUID exists in active notes registry.
* **Post-conditions**:
  * Returns complete note representation (`id`, `title`, `content`, `theme`, `monospace`, `zoom`, `width`, `height`).

### `UC-70.10.21` Read non-existent note
* **Trigger**: External AI client calls MCP tool `read_note(id: <UUID>)` with an unknown or invalid UUID.
* **Pre-conditions**: UUID does not match any active note.
* **Post-conditions**:
  * Returns a D-Bus / JSON-RPC error: `Note with ID '<UUID>' was not found.`

---

## 70.20 Note creation, mutation, and deletion

### `UC-70.20.10` Create note via MCP tool
* **Trigger**: External AI client calls MCP tool `create_note(title, content, theme)`.
* **Pre-conditions**: Total open notes count is below `MAX_ACTIVE_NOTES` (50).
* **Post-conditions**:
  * Instantiates a new `StickyNoteWindow` with a generated UUID.
  * Sets window title, text body, and theme color.
  * Spawns and presents the window on the desktop in real time.
  * Immediately triggers storage persistence.
  * Returns created note representation.

### `UC-70.20.20` Update existing note via MCP tool
* **Trigger**: External AI client calls MCP tool `update_note(id, title, content, theme)`.
* **Pre-conditions**: Target note exists.
* **Post-conditions**:
  * Updates the corresponding `StickyNoteWindow` view live on the desktop.
  * Triggers immediate disk save.
  * Returns updated note representation.

### `UC-70.20.30` Delete note via MCP tool
* **Trigger**: External AI client calls MCP tool `delete_note(id: <UUID>)`.
* **Pre-conditions**: Target note exists.
* **Post-conditions**:
  * Closes and removes the `StickyNoteWindow` from the desktop.
  * Saves remaining active notes immediately.
  * Returns `true`.

---

## 70.30 Keyword search

### `UC-70.30.10` Case-insensitive note search
* **Trigger**: External AI client calls MCP tool `search_notes(query: <string>)`.
* **Pre-conditions**: Query string length is within `MAX_SEARCH_QUERY_LENGTH` (120 chars).
* **Post-conditions**:
  * Searches active note titles and text contents case-insensitively.
  * Returns matching notes capped at `MAX_SEARCH_RESULTS` (20).

---

## 70.40 Defensive limits and guardrails

### `UC-70.40.10` Content length limit enforcement
* **Trigger**: External client attempts to create or update note with body exceeding `MAX_NOTE_CONTENT_LENGTH` (10,000 chars).
* **Post-conditions**:
  * Rejects request at both Pydantic schema validation layer and native Vala core with an explicit error.
  * Preserves UI thread responsiveness in `MarkdownBuffer`.

### `UC-70.40.20` Active notes ceiling enforcement
* **Trigger**: External client attempts to call `create_note` when 50 active notes are already open.
* **Post-conditions**:
  * Rejects note creation with error: `Maximum active notes limit reached (50). Please delete or clean up unused notes.`
  * Prevents window explosion and desktop compositor texture exhaustion.
