# Jots Model Context Protocol (MCP) Server

A native Model Context Protocol (MCP) server for [Jots](https://github.com/codemedic/elly-code-jorts), enabling AI agents and assistants (Claude Desktop, Cursor, Gemini CLI, Antigravity) to query, create, update, search, and delete sticky notes with real-time desktop synchronization.

## Quick Start

### Running with `uvx`
```bash
uvx --from ./mcp-server jots-mcp
```

### Running with `pipx`
```bash
pipx run --spec ./mcp-server jots-mcp
```

## Tools Provided
- `list_notes`: List all active sticky notes on your desktop.
- `read_note(id)`: Read the content and metadata of a specific note.
- `create_note(title, content, theme)`: Create and display a new note on the desktop.
- `update_note(id, title, content, theme)`: Update an existing note's content or title live.
- `delete_note(id)`: Close and delete a note by its ID.
- `search_notes(query)`: Search note titles and bodies.

## Resources Provided
- `jots://notes`: Context summary of all open notes.
- `jots://notes/{id}`: Context content of a specific note.

## Guardrails
- **Max Note Content**: 10,000 characters (~10 KB / ~2,000 words).
- **Max Note Title**: 120 characters.
- **Max Active Notes**: 50 active notes ceiling.
