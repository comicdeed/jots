# Domain 80: Full-Text Search and Discovery

Real-time searching across active desktop windows and stored Markdown files, relevance ranking, highlighted snippet extraction, and keyboard navigation.

---

## 80.10 Search Query Execution & Ranking

### `UC-80.10.10` Exact token search
* **Trigger**: User inputs an exact keyword query in the search popover or via MCP `search_notes`.
* **Pre-conditions**: Stored notes or open note buffers contain the matching token.
* **Post-conditions**:
  * Matches the query token against note titles and note markdown bodies.
  * Returns matching `SearchResult` objects with positive relevance scores.

### `UC-80.10.20` Case-insensitive substring matching
* **Trigger**: User inputs mixed-case or lowercase query (e.g. `apples` matching `Apples`).
* **Pre-conditions**: Content contains case-variant text.
* **Post-conditions**:
  * Matches query case-insensitively using UTF-8 `casefold()`.
  * Preserves original casing in the note content.

### `UC-80.10.30` Ranking: Title matches vs content matches & open notes
* **Trigger**: Search query matches multiple notes across titles and bodies.
* **Pre-conditions**: Multiple search matches exist.
* **Post-conditions**:
  * Title matches receive higher base scoring than body matches.
  * Currently open sticky note windows receive higher priority ranking over closed disk files.
  * Results are sorted strictly by descending score.

### `UC-80.10.40` Highlighted snippet extraction with Pango markup
* **Trigger**: Search result has matching body text.
* **Pre-conditions**: Body text contains query match.
* **Post-conditions**:
  * Extracts a contextual snippet window around the match (up to 80 characters).
  * Safely escapes special XML/Pango entities (`&`, `<`, `>`).
  * Wraps matched search terms in `<b><span foreground="...">...</span></b>` for high-contrast highlighting.

### `UC-80.10.50` Empty and whitespace queries
* **Trigger**: Search input is empty, null, or whitespace-only.
* **Pre-conditions**: Search popover opened.
* **Post-conditions**:
  * Returns an empty results list immediately with zero disk I/O.

### `UC-80.10.60` Search guardrail limits
* **Trigger**: Search matches exceed `MAX_SEARCH_RESULTS` (20 items).
* **Pre-conditions**: Corpus contains large note collection.
* **Post-conditions**:
  * Caps returned results to the top 20 highest-ranked matches to maintain 60 FPS UI performance.

### `UC-80.10.70` JSON serialization output
* **Trigger**: MCP server calls `search_notes(query)`.
* **Pre-conditions**: Valid search query executed.
* **Post-conditions**:
  * Serializes results into a `Json.Array` containing `id`, `title`, `snippet`, `score`, `is_open`, and `theme`.
