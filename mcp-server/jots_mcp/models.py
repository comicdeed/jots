"""Data models and guardrail constants for Jots MCP Server."""

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field

# Native component guardrails (matches Jots Constants.vala)
MAX_NOTE_CONTENT_LENGTH = 10000
MAX_NOTE_TITLE_LENGTH = 120
MAX_SEARCH_QUERY_LENGTH = 120
MAX_ACTIVE_NOTES = 50


class Theme(str, Enum):
    BLUEBERRY = "blueberry"
    MINT = "mint"
    LIME = "lime"
    BANANA = "banana"
    ORANGE = "orange"
    STRAWBERRY = "strawberry"
    BUBBLEGUM = "bubblegum"
    GRAPE = "grape"
    COCOA = "cocoa"
    SLATE = "slate"
    LATTE = "latte"


THEME_ID_MAP = {
    0: Theme.BLUEBERRY,
    1: Theme.MINT,
    2: Theme.LIME,
    3: Theme.BANANA,
    4: Theme.ORANGE,
    5: Theme.STRAWBERRY,
    6: Theme.BUBBLEGUM,
    7: Theme.GRAPE,
    8: Theme.COCOA,
    9: Theme.SLATE,
    10: Theme.LATTE,
}


class NoteSummary(BaseModel):
    id: str = Field(description="Unique note identifier (UUID)")
    title: str = Field(description="Title of the sticky note")
    theme: str = Field(description="Theme color name")
    content_length: int = Field(description="Character count of note body")
    monospace: bool = Field(default=False, description="Whether monospace font is enabled")


class NoteDetail(BaseModel):
    id: str = Field(description="Unique note identifier (UUID)")
    title: str = Field(description="Title of the sticky note")
    theme: str = Field(description="Theme color name")
    content: str = Field(description="Full text body of the note")
    monospace: bool = Field(default=False, description="Whether monospace font is enabled")
    zoom: int = Field(default=100, description="Zoom percentage (20-300)")
    width: int = Field(default=290, description="Window width in pixels")
    height: int = Field(default=320, description="Window height in pixels")


def parse_note_dict(data: dict) -> NoteDetail:
    """Parse raw JSON dict from Jots DBus into NoteDetail."""
    theme_val = data.get("color", 0)
    if isinstance(theme_val, int):
        theme_str = THEME_ID_MAP.get(theme_val, Theme.BLUEBERRY).value
    elif isinstance(theme_val, str):
        theme_str = theme_val.lower()
    else:
        theme_str = Theme.BLUEBERRY.value

    return NoteDetail(
        id=str(data.get("id", "")),
        title=str(data.get("title", "")),
        theme=theme_str,
        content=str(data.get("content", "")),
        monospace=bool(data.get("monospace", False)),
        zoom=int(data.get("zoom", 100)),
        width=int(data.get("width", 290)),
        height=int(data.get("height", 320)),
    )
