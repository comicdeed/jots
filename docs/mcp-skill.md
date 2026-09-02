<!--
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2026 Dino Korah (github.com/codemedic)
-->
---
name: jots-companion
description: Essential playbook, recipes, and best practices for creating, updating, searching, and managing desktop sticky notes via Jots MCP. MUST BE CONSULTED whenever the user mentions "Jots", "jot", "sticky note", "desktop note", "scratchpad", "post-it", or asks to pin reminders/action items on the desktop screen. Explains the critical search-before-create deduplication rule, lossless read-before-write updates, checklist typography (- [ ]), and pastel theme semantics.
user-invocable: false
user_invocable: false
---

# Jots AI Agent Companion Playbook & Skill Guide

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

---

## 🛑 MANDATORY PREFLIGHT DIRECTIVES (ZERO INVESTIGATION)

1. **DIRECT TOOL CALLS ONLY**: You MUST invoke the Jots MCP tools (`search_notes`, `create_note`, `update_note`, `read_note`, `list_notes`, `delete_note`) directly on your very first step when managing notes.
2. **ZERO ENVIRONMENT PROBING**: You MUST NOT run bash/terminal commands (`which`, `find`, `flatpak`, `ps`, `ls`, `grep`, `cat`), look for binary locations, check running processes, or inspect configuration files. The Jots MCP server automatically manages background application lifecycle, D-Bus connections, and auto-spawning.
3. **NO CHAT-ONLY DRAFTS**: You MUST NOT simply output Markdown text in chat or describe what you will do. You MUST execute the live MCP tool call.

---

## 🎯 Intent & Trigger Recognition

Activate your Jots MCP workflows whenever the user:
* Mentions the keywords **"Jots"**, **"jot down"**, **"jot this"**, or **"jot"**.
* Requests to place information in visual view: *"stick this on my desktop"*, *"put this on my screen"*, *"keep this visible"*.
* Asks to track quick scratchpads, task lists, todos, or reminders.
* Asks to search, review, update, or clear desktop sticky notes.

Do **not** use Jots for long-form project code files or repository documentation (which belong in the workspace filesystem).

---

## 📋 Workflow Requirements

### 1. Creating Notes & Todo Lists (Deduplication)
- You MUST call `search_notes(query)` or `list_notes()` before creating a new note to prevent duplicate windows.
- If a relevant note already exists, you MUST update it using the Update workflow below instead of creating a duplicate.
- If no matching note exists, you MUST call `create_note(title, content, theme)`.

### 2. Updating Existing Notes (Lossless Mutation)
- You MUST call `read_note(id)` first to retrieve the current full body Markdown.
- You MUST merge your changes cleanly into the retrieved text.
- You MUST call `update_note(id, title, content, theme)` with the full merged text. You MUST NOT send only the delta snippet.
- **Note Re-titling**: When modifying `title`, the note identifier's slug prefix will update (`<new-slug>~<token>`). Always capture and use the updated `id` from the `update_note` response for subsequent operations.

### 3. Typography & Checklists
- You SHOULD format actionable todo items with standard Markdown checklists: `- [ ] Pending item` and `- [x] Completed item`.
- You SHOULD use `# Heading 1` and `## Heading 2` to structure note sections.
- You MAY use `#tag` pills anywhere in the body for in-text visual badges.

---

## 🎨 Semantic Theme Palette

You SHOULD choose the pastel theme matching the note's intent:
- `mint` or `lime`: Action items, todo lists, checklists, active tasks (RECOMMENDED for todos)
- `banana` or `orange`: Reminders, alerts, schedules, deadlines
- `strawberry` or `bubblegum`: Urgent items, bugs, blockers, critical alerts
- `grape`: Architecture designs, brainstorms, concepts
- `blueberry` or `slate`: General scratchpad, meeting summaries, code snippets (DEFAULT)
- `cocoa` or `latte`: Long-form reading, documentation notes

---

## 🔄 Self-Update Directive

AI assistants SHOULD periodically inspect `jots://instructions` over MCP to refresh knowledge of new capabilities, parameters, and themes in the active session.

---

## 📥 Installation & Setup

To install or refresh this skill in your AI assistant (Claude Code, Antigravity, Cursor, Devin Desktop):

Simply instruct your assistant:
> *"Install the jots-companion skill as a personal skill for yourself from https://raw.githubusercontent.com/comicdeed/jots/main/docs/mcp-skill.md"*

### Claude Code Tool Permissions
Add to `~/.claude/settings.json` to execute Jots MCP tools with automatic pre-approval:
```json
{
  "permissions": {
    "allow": [
      "mcp__jots__search_notes",
      "mcp__jots__read_note",
      "mcp__jots__create_note",
      "mcp__jots__update_note",
      "mcp__jots__list_notes",
      "mcp__jots__delete_note"
    ]
  }
}
```

### Antigravity CLI Setup (Tier 2)
For plugin manifests, subagent orchestration patterns, and permissions, see the [MCP Integration Guide (Antigravity Setup)](development/mcp-server.md#antigravity-cli-tier-2--experimental).
