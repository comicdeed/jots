/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots {

    public interface ActiveNotesProvider : GLib.Object {
        public abstract Gee.List<NoteData> get_active_notes ();
    }

    /**
     * Search service providing full-text search across active and stored notes.
     */
    public class SearchService : GLib.Object {
        private ActiveNotesProvider? active_notes_provider;
        private Storage storage;

        public SearchService (Storage storage, ActiveNotesProvider? active_provider = null) {
            this.storage = storage;
            this.active_notes_provider = active_provider;
        }

        /**
         * Perform a full-text search query across active in-memory notes and closed disk notes.
         */
        public Gee.ArrayList<SearchResult> search (string query, int limit = MAX_SEARCH_RESULTS) {
            var results = new Gee.ArrayList<SearchResult> ();
            var stripped = query.strip ();
            if (stripped.length == 0) {
                return results;
            }

            var query_folded = stripped.casefold ();
            var active_ids = new Gee.HashSet<string> ();

            // 1. Scan active windows in memory (live buffers) via provider
            if (active_notes_provider != null) {
                var active_notes = active_notes_provider.get_active_notes ();
                if (active_notes != null) {
                    foreach (var data in active_notes) {
                        active_ids.add (data.id);
                        int score = calculate_score (data.title, data.content, query_folded, true);
                        if (score > 0) {
                            var snippet = extract_snippet (data.content, query_folded, data.title);
                            results.add (new SearchResult (data.id, data.title, data.theme, true, score, snippet));
                        }
                    }
                }
            }

            // 2. Scan closed stored notes on disk
            var stored_notes = storage.load_all ();
            foreach (var data in stored_notes) {
                if (active_ids.contains (data.id)) {
                    continue; // Skip already evaluated open notes
                }
                int score = calculate_score (data.title, data.content, query_folded, false);
                if (score > 0) {
                    var snippet = extract_snippet (data.content, query_folded, data.title);
                    results.add (new SearchResult (data.id, data.title, data.theme, false, score, snippet));
                }
            }

            // 3. Sort by descending relevance score
            results.sort (SearchResult.compare_score_desc);

            // 4. Truncate to limit
            int max_count = int.min (limit, MAX_SEARCH_RESULTS);
            if (results.size > max_count) {
                var truncated = new Gee.ArrayList<SearchResult> ();
                for (int i = 0; i < max_count; i++) {
                    truncated.add (results.get (i));
                }
                return truncated;
            }

            return results;
        }

        /**
         * Search and serialize results directly to a JSON string for D-Bus / MCP consumption.
         */
        public string search_json (string query, int limit = MAX_SEARCH_RESULTS) {
            var results = search (query, limit);
            var array = new Json.Array ();
            foreach (var res in results) {
                array.add_object_element (res.to_json ());
            }

            var node = new Json.Node (Json.NodeType.ARRAY);
            node.set_array (array);
            var gen = new Json.Generator ();
            gen.set_root (node);
            return gen.to_data (null);
        }

        /**
         * Calculate relevance score based on match position and frequency.
         */
        private int calculate_score (string title, string content, string query_folded, bool is_active) {
            int score = 0;
            var title_folded = title.casefold ();
            var content_folded = content.casefold ();

            // Title relevance
            if (title_folded == query_folded) {
                score += 150;
            } else if (title_folded.has_prefix (query_folded)) {
                score += 120;
            } else if (title_folded.contains (query_folded)) {
                score += 100;
            }

            // Content relevance
            if (content_folded.contains (query_folded)) {
                int count = count_occurrences (content_folded, query_folded);
                score += int.min (count * 10, 50);
            }

            // Active open note bonus
            if (score > 0 && is_active) {
                score += 5;
            }

            return score;
        }

        /**
         * Count non-overlapping occurrences of query in target text.
         */
        private int count_occurrences (string text, string query) {
            int count = 0;
            int pos = 0;
            while (true) {
                int index = text.index_of (query, pos);
                if (index < 0) break;
                count++;
                pos = index + query.length;
            }
            return count;
        }

        /**
         * Extract a concise snippet around the match with bold highlight markup.
         */
        public string extract_snippet (string content, string query_folded, string fallback_title) {
            var content_clean = content.strip ();
            if (content_clean.length == 0) {
                return Markup.escape_text (fallback_title);
            }

            var content_folded = content_clean.casefold ();
            int match_index = content_folded.index_of (query_folded);

            if (match_index < 0) {
                // If content did not match (e.g. title match only), return the first 90 chars of content
                int preview_len = int.min (90, content_clean.length);
                var preview = content_clean.substring (0, preview_len);
                if (content_clean.length > 90) preview += "…";
                return Markup.escape_text (preview);
            }

            // Calculate context boundary window (~35 chars before, ~55 chars after)
            int start = int.max (0, match_index - 35);
            int end = int.min (content_clean.length, match_index + query_folded.length + 55);

            // Expand to nearest whitespace word boundaries
            if (start > 0) {
                int space = content_clean.index_of (" ", start);
                if (space >= 0 && space < match_index) {
                    start = space + 1;
                }
            }

            if (end < content_clean.length) {
                int space = content_clean.index_of (" ", end);
                if (space >= 0 && space < end + 15) {
                    end = space;
                }
            }

            var raw_snippet = content_clean.substring (start, end - start);
            var escaped_snippet = Markup.escape_text (raw_snippet);

            // Highlight matched term using regex
            try {
                var escaped_query = Regex.escape_string (Markup.escape_text (query_folded));
                var highlight_regex = new Regex ("(" + escaped_query + ")", RegexCompileFlags.CASELESS);
                escaped_snippet = highlight_regex.replace (escaped_snippet, -1, 0, "<b>\\1</b>");
            } catch (Error e) {
                debug ("Highlight regex error: %s", e.message);
            }

            string result = escaped_snippet;
            if (start > 0) result = "…" + result;
            if (end < content_clean.length) result = result + "…";

            return result;
        }
    }
}
