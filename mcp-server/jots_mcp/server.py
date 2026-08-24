"""FastMCP Server for Jots Sticky Notes."""

import sys
from typing import Any, Dict, List, Optional
from typing_extensions import Annotated
from pydantic import Field

from mcp.server.mcpserver import MCPServer
from jots_mcp.dbus_client import JotsDbusClient
from jots_mcp.models import (
    MAX_NOTE_CONTENT_LENGTH,
    MAX_NOTE_TITLE_LENGTH,
    MAX_SEARCH_QUERY_LENGTH,
    NoteDetail,
    NoteSummary,
)

mcp = MCPServer("jots", description="Jots Sticky Notes MCP Server")
_client = JotsDbusClient()


def get_client() -> JotsDbusClient:
    return _client


@mcp.tool(name="list_notes", description="List all open sticky notes on the desktop with metadata and summary.")
async def list_notes() -> List[Dict[str, Any]]:
    """Retrieve summaries of all active notes."""
    client = get_client()
    summaries = await client.list_notes()
    return [s.model_dump() for s in summaries]


@mcp.tool(name="read_note", description="Read the full text content, theme, and properties of a specific note by ID.")
async def read_note(
    id: Annotated[str, Field(description="The unique UUID of the note to read")]
) -> Dict[str, Any]:
    """Fetch complete note detail."""
    client = get_client()
    detail = await client.get_note(id)
    return detail.model_dump()


@mcp.tool(name="create_note", description="Create a new sticky note window on the desktop with given title, body, and theme color.")
async def create_note(
    title: Annotated[
        str,
        Field(
            default="",
            max_length=MAX_NOTE_TITLE_LENGTH,
            description=f"Title of the note (max {MAX_NOTE_TITLE_LENGTH} chars)",
        ),
    ] = "",
    content: Annotated[
        str,
        Field(
            default="",
            max_length=MAX_NOTE_CONTENT_LENGTH,
            description=f"Body text of the note (max {MAX_NOTE_CONTENT_LENGTH} chars)",
        ),
    ] = "",
    theme: Annotated[
        str,
        Field(
            default="blueberry",
            description="Theme color: blueberry, mint, lime, banana, orange, strawberry, bubblegum, grape, cocoa, slate, latte",
        ),
    ] = "blueberry",
) -> Dict[str, Any]:
    """Create a new note and render it immediately on screen."""
    client = get_client()
    created = await client.create_note(title=title, content=content, theme=theme)
    return created.model_dump()


@mcp.tool(name="update_note", description="Update the content, title, or theme color of an existing sticky note in real time.")
async def update_note(
    id: Annotated[str, Field(description="The UUID of the note to update")],
    title: Annotated[
        Optional[str],
        Field(
            default=None,
            max_length=MAX_NOTE_TITLE_LENGTH,
            description=f"New note title (max {MAX_NOTE_TITLE_LENGTH} chars)",
        ),
    ] = None,
    content: Annotated[
        Optional[str],
        Field(
            default=None,
            max_length=MAX_NOTE_CONTENT_LENGTH,
            description=f"New body text (max {MAX_NOTE_CONTENT_LENGTH} chars)",
        ),
    ] = None,
    theme: Annotated[
        Optional[str],
        Field(
            default=None,
            description="New theme color name (e.g. mint, banana, cocoa)",
        ),
    ] = None,
) -> Dict[str, Any]:
    """Update note attributes and synchronize live window display."""
    client = get_client()
    updated = await client.update_note(note_id=id, title=title, content=content, theme=theme)
    return updated.model_dump()


@mcp.tool(name="delete_note", description="Delete and close a sticky note window from the desktop.")
async def delete_note(
    id: Annotated[str, Field(description="The UUID of the note to delete")]
) -> bool:
    """Close and remove note."""
    client = get_client()
    return await client.delete_note(id)


@mcp.tool(name="search_notes", description="Search through all sticky notes matching text in the title or content.")
async def search_notes(
    query: Annotated[
        str,
        Field(
            max_length=MAX_SEARCH_QUERY_LENGTH,
            description=f"Search term or keyword (max {MAX_SEARCH_QUERY_LENGTH} chars)",
        ),
    ]
) -> List[Dict[str, Any]]:
    """Search notes for query string."""
    client = get_client()
    results = await client.search_notes(query)
    return [r.model_dump() for r in results]


# Resources
@mcp.resource("jots://notes")
async def get_all_notes_resource() -> str:
    """Return all notes as a structured text resource."""
    client = get_client()
    summaries = await client.list_notes()
    lines = ["# Jots Sticky Notes Overview", ""]
    for s in summaries:
        lines.append(f"- **{s.title}** (ID: `{s.id}`, Theme: {s.theme}, Length: {s.content_length} chars)")
    return "\n".join(lines)


@mcp.resource("jots://notes/{id}")
async def get_note_resource(id: str) -> str:
    """Return a single note body as a Markdown resource."""
    client = get_client()
    note = await client.get_note(id)
    return f"# {note.title}\n*Theme: {note.theme}* (ID: `{note.id}`)\n\n{note.content}"


# Prompts
@mcp.prompt("create_action_items")
def prompt_create_action_items(action_items: str) -> str:
    """Create a formatted sticky note from action items."""
    return f"Please create a new Jots sticky note with theme 'mint' containing the following action items as a markdown checklist:\n\n{action_items}"


@mcp.prompt("summarize_notes")
def prompt_summarize_notes() -> str:
    """Prompt to summarize all current desktop sticky notes."""
    return "Please read all open sticky notes using list_notes and provide a concise summary grouped by theme."


def main():
    """Entrypoint for the jots-mcp executable."""
    mcp.run()


if __name__ == "__main__":
    main()
