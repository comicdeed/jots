"""Unit and integration tests for Jots MCP Server."""

import pytest
from unittest.mock import AsyncMock, patch
from pydantic import ValidationError

from jots_mcp.models import (
    MAX_NOTE_CONTENT_LENGTH,
    MAX_NOTE_TITLE_LENGTH,
    MAX_SEARCH_QUERY_LENGTH,
    NoteDetail,
    NoteSummary,
    Theme,
    parse_note_dict,
)
from jots_mcp.server import (
    create_note,
    delete_note,
    get_all_notes_resource,
    get_note_resource,
    list_notes,
    prompt_create_action_items,
    prompt_summarize_notes,
    read_note,
    search_notes,
    update_note,
)


def test_parse_note_dict():
    """Verify raw JSON parsing from Jots DBus to NoteDetail."""
    raw = {
        "id": "1234-5678",
        "title": "My Note",
        "color": 1,  # Mint
        "content": "Hello world",
        "monospace": True,
        "zoom": 120,
        "width": 300,
        "height": 400,
    }
    detail = parse_note_dict(raw)
    assert detail.id == "1234-5678"
    assert detail.title == "My Note"
    assert detail.theme == "mint"
    assert detail.content == "Hello world"
    assert detail.monospace is True
    assert detail.zoom == 120
    assert detail.width == 300
    assert detail.height == 400


def test_parse_note_dict_fallback():
    """Verify fallback for missing or corrupted fields."""
    detail = parse_note_dict({})
    assert detail.id == ""
    assert detail.title == ""
    assert detail.theme == "blueberry"
    assert detail.content == ""
    assert detail.monospace is False


@pytest.mark.asyncio
async def test_list_notes_tool():
    """Verify list_notes tool returns formatted dictionaries."""
    mock_summaries = [
        NoteSummary(
            id="uuid-1",
            title="Note 1",
            theme="mint",
            content_length=25,
            monospace=False,
        ),
        NoteSummary(
            id="uuid-2",
            title="Note 2",
            theme="orange",
            content_length=50,
            monospace=True,
        ),
    ]

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.list_notes.return_value = mock_summaries
        mock_get_client.return_value = mock_client

        results = await list_notes()
        assert len(results) == 2
        assert results[0]["id"] == "uuid-1"
        assert results[0]["title"] == "Note 1"
        assert results[0]["theme"] == "mint"
        assert results[0]["content_length"] == 25


@pytest.mark.asyncio
async def test_read_note_tool():
    """Verify read_note tool fetches note detail."""
    mock_detail = NoteDetail(
        id="uuid-1",
        title="Todo List",
        theme="blueberry",
        content="- [x] Item 1\n- [ ] Item 2",
        monospace=False,
        zoom=100,
        width=290,
        height=320,
    )

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get_note.return_value = mock_detail
        mock_get_client.return_value = mock_client

        result = await read_note(id="uuid-1")
        assert result["id"] == "uuid-1"
        assert result["title"] == "Todo List"
        assert result["content"] == "- [x] Item 1\n- [ ] Item 2"


@pytest.mark.asyncio
async def test_create_note_tool():
    """Verify create_note tool sends correct properties."""
    mock_created = NoteDetail(
        id="uuid-new",
        title="Shopping",
        theme="banana",
        content="Milk, Eggs",
        monospace=False,
        zoom=100,
        width=290,
        height=320,
    )

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.create_note.return_value = mock_created
        mock_get_client.return_value = mock_client

        result = await create_note(title="Shopping", content="Milk, Eggs", theme="banana")
        mock_client.create_note.assert_called_once_with(
            title="Shopping", content="Milk, Eggs", theme="banana"
        )
        assert result["id"] == "uuid-new"
        assert result["title"] == "Shopping"


@pytest.mark.asyncio
async def test_update_note_tool():
    """Verify update_note tool modifies note."""
    mock_updated = NoteDetail(
        id="uuid-1",
        title="Updated Title",
        theme="mint",
        content="Updated Content",
        monospace=False,
        zoom=100,
        width=290,
        height=320,
    )

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.update_note.return_value = mock_updated
        mock_get_client.return_value = mock_client

        result = await update_note(id="uuid-1", title="Updated Title", content="Updated Content")
        mock_client.update_note.assert_called_once_with(
            note_id="uuid-1", title="Updated Title", content="Updated Content", theme=None
        )
        assert result["title"] == "Updated Title"
        assert result["content"] == "Updated Content"


@pytest.mark.asyncio
async def test_delete_note_tool():
    """Verify delete_note tool."""
    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.delete_note.return_value = True
        mock_get_client.return_value = mock_client

        result = await delete_note(id="uuid-1")
        assert result is True
        mock_client.delete_note.assert_called_once_with("uuid-1")


@pytest.mark.asyncio
async def test_search_notes_tool():
    """Verify search_notes tool."""
    mock_matches = [
        NoteDetail(
            id="uuid-1",
            title="Search Target",
            theme="cocoa",
            content="Some matching content",
            monospace=False,
            zoom=100,
            width=290,
            height=320,
        )
    ]

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.search_notes.return_value = mock_matches
        mock_get_client.return_value = mock_client

        results = await search_notes(query="target")
        assert len(results) == 1
        assert results[0]["id"] == "uuid-1"
        mock_client.search_notes.assert_called_once_with("target")


@pytest.mark.asyncio
async def test_resources():
    """Verify MCP context resources."""
    mock_summaries = [
        NoteSummary(
            id="uuid-1",
            title="Overview Note",
            theme="mint",
            content_length=15,
            monospace=False,
        )
    ]
    mock_detail = NoteDetail(
        id="uuid-1",
        title="Overview Note",
        theme="mint",
        content="Meeting at 2pm",
        monospace=False,
        zoom=100,
        width=290,
        height=320,
    )

    with patch("jots_mcp.server.get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.list_notes.return_value = mock_summaries
        mock_client.get_note.return_value = mock_detail
        mock_get_client.return_value = mock_client

        all_res = await get_all_notes_resource()
        assert "Overview Note" in all_res
        assert "uuid-1" in all_res

        single_res = await get_note_resource("uuid-1")
        assert "# Overview Note" in single_res
        assert "Meeting at 2pm" in single_res


def test_prompts():
    """Verify MCP prompt templates."""
    action_prompt = prompt_create_action_items("- Fix bug\n- Write docs")
    assert "Fix bug" in action_prompt
    assert "mint" in action_prompt

    summary_prompt = prompt_summarize_notes()
    assert "list_notes" in summary_prompt
