/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2017-2024 Lains
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 *                          2025-2026 Stella & Charlie (teamcons.carrd.co)
 */

namespace Jots {

    /**
     * Handles conversion between NoteData objects and Markdown files with YAML front matter.
     */
    public class MarkdownSerializer : Object {

        private const string FRONT_MATTER_DELIMITER = "---";

        /**
         * Serializes a NoteData instance to a Markdown string with YAML front matter.
         */
        public static string serialize (NoteData note) {
            var sb = new StringBuilder ();
            sb.append (FRONT_MATTER_DELIMITER);
            sb.append ("\n");

            sb.append_printf ("id: \"%s\"\n", escape_yaml_string (note.id));
            sb.append_printf ("title: \"%s\"\n", escape_yaml_string (note.title));
            sb.append_printf ("color: %d\n", (int) note.theme);
            sb.append_printf ("theme: \"%s\"\n", note.theme.to_string ());
            sb.append_printf ("monospace: %s\n", note.monospace ? "true" : "false");
            sb.append_printf ("zoom: %d\n", note.zoom);
            sb.append_printf ("width: %d\n", note.width);
            sb.append_printf ("height: %d\n", note.height);
            sb.append_printf ("readonly: %s\n", note.readonly ? "true" : "false");
            sb.append_printf ("always_visible: %s\n", note.always_visible ? "true" : "false");

            sb.append (FRONT_MATTER_DELIMITER);
            sb.append ("\n");

            if (note.content != null && note.content.length > 0) {
                sb.append (note.content);
            }

            return sb.str;
        }

        /**
         * Deserializes a Markdown string (with or without YAML front matter) into a NoteData object.
         */
        public static NoteData deserialize (string raw_content, string? fallback_id = null, string? fallback_title = null) {
            var note = new NoteData ();
            if (fallback_id != null && fallback_id.strip () != "") {
                note.id = fallback_id;
            }

            var trimmed = raw_content;

            if (trimmed.has_prefix (FRONT_MATTER_DELIMITER)) {
                // Find the second delimiter
                var rest = trimmed.substring (FRONT_MATTER_DELIMITER.length);
                // Handle potential \r\n or \n after opening delimiter
                int newline_offset = 0;
                if (rest.has_prefix ("\r\n")) {
                    newline_offset = 2;
                } else if (rest.has_prefix ("\n")) {
                    newline_offset = 1;
                }

                rest = rest.substring (newline_offset);
                var end_idx = rest.index_of (FRONT_MATTER_DELIMITER);

                if (end_idx >= 0) {
                    var front_matter = rest.substring (0, end_idx);
                    var body = rest.substring (end_idx + FRONT_MATTER_DELIMITER.length);

                    // Clean leading newline from body
                    if (body.has_prefix ("\r\n")) {
                        body = body.substring (2);
                    } else if (body.has_prefix ("\n")) {
                        body = body.substring (1);
                    }

                    parse_front_matter (front_matter, note);
                    note.content = body;
                    return note;
                }
            }

            // No valid front matter found: treat whole file as content
            note.content = raw_content;
            if (fallback_title != null && fallback_title.strip () != "") {
                note.title = fallback_title;
            } else {
                // Extract first heading if available
                var first_line_end = raw_content.index_of ("\n");
                var first_line = first_line_end >= 0 ? raw_content.substring (0, first_line_end).strip () : raw_content.strip ();
                if (first_line.has_prefix ("# ")) {
                    note.title = first_line.substring (2).strip ();
                }
            }

            return note;
        }

        private static void parse_front_matter (string front_matter, NoteData note) {
            var lines = front_matter.split ("\n");
            foreach (var line in lines) {
                var trimmed_line = line.strip ();
                if (trimmed_line == "" || trimmed_line.has_prefix ("#")) {
                    continue;
                }

                var colon_idx = trimmed_line.index_of (":");
                if (colon_idx <= 0) {
                    continue;
                }

                var key = trimmed_line.substring (0, colon_idx).strip ().down ();
                var val = trimmed_line.substring (colon_idx + 1).strip ();

                // Strip quotes if present
                val = unquote (val);

                switch (key) {
                    case "id":
                        if (val != "") {
                            note.id = val;
                        }
                        break;
                    case "title":
                        note.title = val;
                        break;
                    case "color":
                        int color_int = int.parse (val);
                        if (color_int >= 0 && color_int < 10) {
                            note.theme = (Themes) color_int;
                        }
                        break;
                    case "theme":
                        note.theme = Themes.from_string (val, note.theme);
                        break;
                    case "monospace":
                        note.monospace = (val.down () == "true" || val == "1");
                        break;
                    case "zoom":
                        int zoom_val = int.parse (val);
                        if (zoom_val < ZOOM_MIN) {
                            zoom_val = ZOOM_MIN;
                        } else if (zoom_val > ZOOM_MAX) {
                            zoom_val = ZOOM_MAX;
                        }
                        note.zoom = zoom_val;
                        break;
                    case "width":
                        int w = int.parse (val);
                        if (w > 50) {
                            note.width = w;
                        }
                        break;
                    case "height":
                        int h = int.parse (val);
                        if (h > 50) {
                            note.height = h;
                        }
                        break;
                    case "readonly":
                        note.readonly = (val.down () == "true" || val == "1");
                        break;
                    case "always_visible":
                        note.always_visible = (val.down () == "true" || val == "1");
                        break;
                }
            }
        }

        private static string escape_yaml_string (string str) {
            return str.replace ("\\", "\\\\").replace ("\"", "\\\"").replace ("\n", "\\n");
        }

        private static string unquote (string str) {
            var res = str.strip ();
            if ((res.has_prefix ("\"") && res.has_suffix ("\"")) || (res.has_prefix ("'") && res.has_suffix ("'"))) {
                if (res.length >= 2) {
                    res = res.substring (1, res.length - 2);
                }
            }
            return res.replace ("\\\"", "\"").replace ("\\\\", "\\").replace ("\\n", "\n");
        }
    }
}
