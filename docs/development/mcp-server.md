# Jots MCP Server Setup & Integration Guide

This guide explains how to connect Model Context Protocol (MCP) clients (such as Claude Desktop, Cursor, Gemini CLI, and Antigravity) to Jots for real-time sticky note automation.

---

## 1. Architecture Overview

```mermaid
graph LR
    subgraph Jots Native Core ["Jots Core (Vala)"]
        Storage["Storage.vala"] --> NoteMgr["NoteManager.vala"]
        NoteMgr --> NoteService["NoteService.vala (io.github.comicdeed.jots.Notes)"]
    end

    subgraph Adapters & Consumers
        MCP["MCP Wrapper (jots-mcp)"] -->|D-Bus| NoteService
        CLI["CLI / Scripts"] -->|D-Bus| NoteService
    end

    Agent[AI Agent / Cursor / Claude] -->|stdio MCP| MCP
```

- **Transport**: Standard input/output (`stdio`) JSON-RPC 2.0.
- **Native IPC**: Native D-Bus session bus communication with the running Jots application (`io.github.comicdeed.jots.Notes` / `io.github.comicdeed.jots.devel`).
- **Encapsulation**: Strict D-Bus boundary; storage internals remain completely private to Jots.

---

## 2. Client Configuration Examples

### Claude Desktop
Add the following to your `claude_desktop_config.json` (located at `~/.config/Claude/claude_desktop_config.json` on Linux):

```json
{
  "mcpServers": {
    "jots": {
      "command": "uvx",
      "args": [
        "--from",
        "/path/to/elly-code-jorts/mcp-server",
        "jots-mcp"
      ]
    }
  }
}
```

### Cursor / VSCode MCP Settings
Add to your `.cursor/mcp.json` or VSCode MCP configuration:

```json
{
  "mcpServers": {
    "jots": {
      "command": "uvx",
      "args": [
        "--from",
        "/path/to/elly-code-jorts/mcp-server",
        "jots-mcp"
      ]
    }
  }
}
```

### Gemini CLI / Antigravity
Configure via `antigravity-cli` MCP server settings or run directly:

```bash
uv run --directory /path/to/elly-code-jorts/mcp-server jots-mcp
```

---

## 3. Available Tools

| Tool | Parameters | Description |
| :--- | :--- | :--- |
| `list_notes` | None | Lists all active sticky notes with title, ID, theme, and length. |
| `read_note` | `id` (string) | Returns complete note text and properties. |
| `create_note` | `title` (str, max 120), `content` (str, max 10000), `theme` (str) | Spawns a new sticky note window on the desktop. |
| `update_note` | `id` (str), `title` (opt), `content` (opt), `theme` (opt) | Updates live note window and persists changes. |
| `delete_note` | `id` (string) | Closes and deletes the target sticky note. |
| `search_notes` | `query` (str, max 120) | Searches note titles and contents case-insensitively. |

---

## 4. Guardrails & Limits

| Guardrail | Limit | Behavior |
| :--- | :--- | :--- |
| **Max Note Content** | `10,000` chars (~10 KB) | Rejects over-length text to protect GTK text buffer rendering performance. |
| **Max Note Title** | `120` chars | Prevents header bar overflow. |
| **Active Notes Ceiling** | `50` notes | Prevents desktop window spam and texture exhaustion. |
| **Search Results** | `20` matches | Caps search results to prevent LLM context token inflation. |
