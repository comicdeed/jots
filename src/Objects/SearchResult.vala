/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots {

    /**
     * Search result record holding match metadata, relevance score, and snippet.
     */
    public class SearchResult : GLib.Object {
        public string id { get; construct set; }
        public string title { get; construct set; }
        public Jots.Themes theme { get; construct set; }
        public bool is_active { get; construct set; }
        public int score { get; construct set; }
        public string snippet { get; construct set; }

        public SearchResult (string id, string title, Jots.Themes theme, bool is_active, int score, string snippet) {
            GLib.Object (
                id: id,
                title: title,
                theme: theme,
                is_active: is_active,
                score: score,
                snippet: snippet
            );
        }

        public Json.Object to_json () {
            var obj = new Json.Object ();
            obj.set_string_member ("id", id);
            obj.set_string_member ("title", title);
            obj.set_string_member ("theme", theme.to_string ());
            obj.set_boolean_member ("is_active", is_active);
            obj.set_int_member ("score", score);
            obj.set_string_member ("snippet", snippet);
            return obj;
        }

        public string to_json_string () {
            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (to_json ());
            var gen = new Json.Generator ();
            gen.set_root (node);
            return gen.to_data (null);
        }

        /**
         * Compare two search results for descending relevance order.
         */
        public static int compare_score_desc (SearchResult a, SearchResult b) {
            if (a.score > b.score) {
                return -1;
            }
            if (a.score < b.score) {
                return 1;
            }
            return (a.title ?? "").collate (b.title ?? "");
        }
    }
}
