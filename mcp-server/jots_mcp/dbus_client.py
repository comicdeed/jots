"""D-Bus client for communicating with the running Jots application."""

import json
import logging
from typing import Any, List, Optional
from dbus_fast.aio import MessageBus
from dbus_fast import BusType

from jots_mcp.models import NoteDetail, NoteSummary, parse_note_dict

logger = logging.getLogger("jots_mcp.dbus")

# Possible application IDs and bus names in priority order
BUS_CANDIDATES = [
    ("io.github.comicdeed.jots", "/io/github/comicdeed/jots/Notes"),
    ("io.github.comicdeed.jots.devel", "/io/github/comicdeed/jots/devel/Notes"),
    ("io.github.comicdeed.jots.devel", "/io/github/comicdeed/jots/Notes"),
    ("io.github.comicdeed.jots", "/io/github/comicdeed/jots"),
    ("io.github.comicdeed.jots.devel", "/io/github/comicdeed/jots/devel"),
    ("io.github.elly_code.jorts", "/io/github/elly_code/jorts/Notes"),
]
INTERFACE_NAME = "io.github.comicdeed.jots.Notes"


class JotsDbusClient:
    """Asynchronous client interacting with Jots over the D-Bus session bus."""

    def __init__(self, bus: Optional[MessageBus] = None):
        self._bus = bus
        self._proxy_interface: Optional[Any] = None

    async def _get_bus(self) -> MessageBus:
        if self._bus is None:
            self._bus = await MessageBus(bus_type=BusType.SESSION).connect()
        return self._bus

    async def get_interface(self) -> Any:
        """Find active Jots D-Bus service on session bus and return proxy interface."""
        bus = await self._get_bus()

        for bus_name, obj_path in BUS_CANDIDATES:
            try:
                introspection = await bus.introspect(bus_name, obj_path)
                proxy_object = bus.get_proxy_object(bus_name, obj_path, introspection)
                interface = proxy_object.get_interface(INTERFACE_NAME)
                self._proxy_interface = interface
                return interface
            except Exception as err:
                logger.debug(f"Candidate {bus_name} at {obj_path} not reachable: {err}")

        # If not found, try base object path
        for bus_name, _ in BUS_CANDIDATES:
            try:
                base_path = "/" + bus_name.replace(".", "/")
                introspection = await bus.introspect(bus_name, base_path)
                proxy_object = bus.get_proxy_object(bus_name, base_path, introspection)
                interface = proxy_object.get_interface(INTERFACE_NAME)
                self._proxy_interface = interface
                return interface
            except Exception:
                pass

        raise ConnectionError(
            "Could not connect to Jots D-Bus service. Ensure Jots is running on your desktop."
        )

    async def list_notes(self) -> List[NoteSummary]:
        """Query all active notes from Jots."""
        iface = await self.get_interface()
        raw_json_str = await iface.call_list_notes()
        raw_list = json.loads(raw_json_str)

        summaries = []
        for item in raw_list:
            detail = parse_note_dict(item)
            summaries.append(
                NoteSummary(
                    id=detail.id,
                    title=detail.title,
                    theme=detail.theme,
                    content_length=len(detail.content),
                    monospace=detail.monospace,
                )
            )
        return summaries

    async def get_note(self, note_id: str) -> NoteDetail:
        """Fetch details for a single note by UUID."""
        iface = await self.get_interface()
        raw_json_str = await iface.call_get_note(note_id)
        raw_data = json.loads(raw_json_str)
        return parse_note_dict(raw_data)

    async def create_note(
        self,
        title: Optional[str] = None,
        content: Optional[str] = None,
        theme: Optional[str] = None,
    ) -> NoteDetail:
        """Create a new sticky note in Jots."""
        iface = await self.get_interface()
        raw_json_str = await iface.call_create_note(
            title if title is not None else "",
            content if content is not None else "",
            theme if theme is not None else "",
        )
        raw_data = json.loads(raw_json_str)
        return parse_note_dict(raw_data)

    async def update_note(
        self,
        note_id: str,
        title: Optional[str] = None,
        content: Optional[str] = None,
        theme: Optional[str] = None,
    ) -> NoteDetail:
        """Update an existing note's title, content, or theme."""
        iface = await self.get_interface()
        raw_json_str = await iface.call_update_note(
            note_id,
            title if title is not None else "",
            content if content is not None else "",
            theme if theme is not None else "",
        )
        raw_data = json.loads(raw_json_str)
        return parse_note_dict(raw_data)

    async def delete_note(self, note_id: str) -> bool:
        """Delete an active note by UUID."""
        iface = await self.get_interface()
        return await iface.call_delete_note(note_id)

    async def search_notes(self, query: str) -> List[NoteDetail]:
        """Search active notes matching query string."""
        iface = await self.get_interface()
        raw_json_str = await iface.call_search_notes(query)
        raw_list = json.loads(raw_json_str)
        return [parse_note_dict(item) for item in raw_list]
