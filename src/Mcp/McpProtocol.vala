/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {
    /**
     * Handles MCP JSON-RPC 2.0 protocol framing, schema generation, and tool/resource routing.
     */
    public class McpProtocol : GLib.Object {
        public const string PROTOCOL_VERSION = "2024-11-05";
        public const string SERVER_NAME = "jots";
        public const string SERVER_VERSION = "4.3.0";

        private NotesProxy? proxy;

        public McpProtocol (NotesProxy? dbus_proxy = null) {
            this.proxy = dbus_proxy;
        }

        public void set_proxy (NotesProxy? dbus_proxy) {
            this.proxy = dbus_proxy;
        }

        /**
         * Process a single incoming JSON-RPC line. Returns a JSON string response or null for notifications.
         */
        public string? process_message (string input_line) {
            var trimmed = input_line.strip ();
            if (trimmed == "") {
                return null;
            }

            var parser = new Json.Parser ();
            try {
                parser.load_from_data (trimmed);
            } catch (GLib.Error e) {
                return format_error (null, -32700, "Parse error: " + e.message);
            }

            var root = parser.get_root ();
            if (root == null || root.get_node_type () != Json.NodeType.OBJECT) {
                return format_error (null, -32600, "Invalid Request: root must be a JSON object");
            }

            var req_obj = root.get_object ();
            var id_node = req_obj.get_member ("id");
            var method = req_obj.get_string_member_with_default ("method", "");

            if (method == "") {
                return format_error (id_node, -32600, "Invalid Request: missing method");
            }

            // Notifications have no ID and expect no response
            if (method == "notifications/initialized" || method == "initialized") {
                return null;
            }

            var params_node = req_obj.get_member ("params");
            var params_obj = (params_node != null && params_node.get_node_type () == Json.NodeType.OBJECT) ? params_node.get_object () : null;

            switch (method) {
                case "initialize":
                    return handle_initialize (id_node, params_obj);

                case "ping":
                    return handle_ping (id_node);

                case "tools/list":
                    return handle_tools_list (id_node);

                case "tools/call":
                    return handle_tools_call (id_node, params_obj);

                case "resources/list":
                    return handle_resources_list (id_node);

                case "resources/read":
                    return handle_resources_read (id_node, params_obj);

                case "prompts/list":
                    return handle_prompts_list (id_node);

                case "prompts/get":
                    return handle_prompts_get (id_node, params_obj);

                default:
                    return format_error (id_node, -32601, "Method not found: " + method);
            }
        }

        private string handle_initialize (Json.Node? id_node, Json.Object? params_obj) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();

            builder.set_member_name ("protocolVersion");
            builder.add_string_value (PROTOCOL_VERSION);

            builder.set_member_name ("capabilities");
            builder.begin_object ();
            builder.set_member_name ("tools");
            builder.begin_object ();
            builder.end_object ();
            builder.set_member_name ("resources");
            builder.begin_object ();
            builder.end_object ();
            builder.set_member_name ("prompts");
            builder.begin_object ();
            builder.end_object ();
            builder.end_object (); // capabilities

            builder.set_member_name ("serverInfo");
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value (SERVER_NAME);
            builder.set_member_name ("version");
            builder.add_string_value (SERVER_VERSION);
            builder.end_object (); // serverInfo

            builder.end_object (); // result
            builder.end_object (); // root

            return generator_to_string (builder);
        }

        private string handle_ping (Json.Node? id_node) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);
            builder.set_member_name ("result");
            builder.begin_object ();
            builder.end_object ();
            builder.end_object ();
            return generator_to_string (builder);
        }

        private string handle_tools_list (Json.Node? id_node) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("tools");
            builder.begin_array ();

            // tool: list_notes
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("list_notes");
            builder.set_member_name ("description");
            builder.add_string_value ("List all open desktop sticky notes with metadata (id, title, theme, content_length, monospace).");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();
            builder.end_object ();
            builder.end_object ();
            builder.end_object ();

            // tool: read_note
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("read_note");
            builder.set_member_name ("description");
            builder.add_string_value ("Read the full text content, title, theme, and window properties of a specific sticky note by its UUID.");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();
            builder.set_member_name ("id");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("The unique UUID of the note to read");
            builder.end_object ();
            builder.end_object ();
            builder.set_member_name ("required");
            builder.begin_array ();
            builder.add_string_value ("id");
            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            // tool: create_note
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("create_note");
            builder.set_member_name ("description");
            builder.add_string_value ("Create and spawn a new sticky note window live on the desktop with given title, body content in Markdown, and pastel theme color.");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();

            builder.set_member_name ("title");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("Title of the note (max 120 chars)");
            builder.end_object ();

            builder.set_member_name ("content");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("Body text of the note in Markdown (max 10,000 chars). Supports headings (#, ##, ###), checklists (- [ ], - [x]), bullet lists (- or *), bold (**text**), italic (*text*), strikethrough (~~text~~), inline code (`code`), code blocks (```), blockquotes (>), and hyperlinks [label](url).");
            builder.end_object ();

            builder.set_member_name ("theme");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("Pastel theme color: blueberry, mint, lime, banana, orange, strawberry, bubblegum, grape, cocoa, slate, latte");
            builder.end_object ();

            builder.end_object (); // properties
            builder.end_object (); // inputSchema
            builder.end_object ();

            // tool: update_note
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("update_note");
            builder.set_member_name ("description");
            builder.add_string_value ("Update the Markdown content, title, or theme color of an existing sticky note in real time. To append text to an existing note, call read_note first to fetch current content, then call update_note with the updated full body text.");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();

            builder.set_member_name ("id");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("The UUID of the note to update");
            builder.end_object ();

            builder.set_member_name ("title");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("New note title (max 120 chars)");
            builder.end_object ();

            builder.set_member_name ("content");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("New full body text in Markdown (max 10,000 chars). Supports headings (#, ##, ###), checklists (- [ ], - [x]), bullet lists (- or *), bold (**text**), italic (*text*), strikethrough (~~text~~), inline code (`code`), code blocks (```), blockquotes (>), and hyperlinks [label](url).");
            builder.end_object ();

            builder.set_member_name ("theme");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("New pastel theme color name");
            builder.end_object ();

            builder.end_object (); // properties
            builder.set_member_name ("required");
            builder.begin_array ();
            builder.add_string_value ("id");
            builder.end_array ();
            builder.end_object (); // inputSchema
            builder.end_object ();

            // tool: delete_note
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("delete_note");
            builder.set_member_name ("description");
            builder.add_string_value ("Delete and close a sticky note window from the desktop by UUID.");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();
            builder.set_member_name ("id");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("The UUID of the note to delete");
            builder.end_object ();
            builder.end_object (); // closes properties
            builder.set_member_name ("required");
            builder.begin_array ();
            builder.add_string_value ("id");
            builder.end_array ();
            builder.end_object (); // closes inputSchema
            builder.end_object (); // closes tool: delete_note

            // tool: search_notes
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("search_notes");
            builder.set_member_name ("description");
            builder.add_string_value ("Search through active desktop sticky notes case-insensitively by keyword in title or body content. Useful before creating a note to prevent duplicates or when finding a note to update.");
            builder.set_member_name ("inputSchema");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("object");
            builder.set_member_name ("properties");
            builder.begin_object ();
            builder.set_member_name ("query");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("string");
            builder.set_member_name ("description");
            builder.add_string_value ("Search term or keyword (max 120 chars)");
            builder.end_object ();
            builder.end_object (); // closes properties
            builder.set_member_name ("required");
            builder.begin_array ();
            builder.add_string_value ("query");
            builder.end_array ();
            builder.end_object (); // closes inputSchema
            builder.end_object (); // closes tool: search_notes

            builder.end_array (); // tools
            builder.end_object (); // result
            builder.end_object (); // root

            return generator_to_string (builder);
        }

        private string handle_tools_call (Json.Node? id_node, Json.Object? params_obj) {
            if (params_obj == null) {
                return format_error (id_node, -32602, "Invalid params: missing parameters object");
            }

            var tool_name = params_obj.get_string_member_with_default ("name", "");
            var args_node = params_obj.get_member ("arguments");
            var args_obj = (args_node != null && args_node.get_node_type () == Json.NodeType.OBJECT) ? args_node.get_object () : new Json.Object ();

            if (proxy == null) {
                return format_tool_error (id_node, "Could not connect to Jots D-Bus service. Ensure Jots is running.");
            }

            try {
                switch (tool_name) {
                    case "list_notes": {
                        var raw_json = proxy.list_notes ();
                        return format_tool_success (id_node, raw_json);
                    }

                    case "read_note": {
                        var note_id = args_obj.get_string_member_with_default ("id", "");
                        if (note_id == "") {
                            return format_error (id_node, -32602, "Invalid params: 'id' is required");
                        }
                        var raw_json = proxy.get_note (note_id);
                        return format_tool_success (id_node, raw_json);
                    }

                    case "create_note": {
                        var title = args_obj.has_member ("title") ? args_obj.get_string_member ("title") : "";
                        var content = args_obj.has_member ("content") ? args_obj.get_string_member ("content") : "";
                        var theme = args_obj.has_member ("theme") ? args_obj.get_string_member ("theme") : "blueberry";

                        if (content.length > MAX_NOTE_CONTENT_LENGTH) {
                            return format_tool_error (id_node, "Content exceeds maximum length of %d characters.".printf (MAX_NOTE_CONTENT_LENGTH));
                        }
                        if (title.length > MAX_NOTE_TITLE_LENGTH) {
                            return format_tool_error (id_node, "Title exceeds maximum length of %d characters.".printf (MAX_NOTE_TITLE_LENGTH));
                        }

                        var raw_json = proxy.create_note (title, content, theme);
                        return format_tool_success (id_node, raw_json);
                    }

                    case "update_note": {
                        var note_id = args_obj.get_string_member_with_default ("id", "");
                        if (note_id == "") {
                            return format_error (id_node, -32602, "Invalid params: 'id' is required");
                        }
                        string? title = args_obj.has_member ("title") ? args_obj.get_string_member ("title") : null;
                        string? content = args_obj.has_member ("content") ? args_obj.get_string_member ("content") : null;
                        string? theme = args_obj.has_member ("theme") ? args_obj.get_string_member ("theme") : null;

                        if (content != null && content.length > MAX_NOTE_CONTENT_LENGTH) {
                            return format_tool_error (id_node, "Content exceeds maximum length of %d characters.".printf (MAX_NOTE_CONTENT_LENGTH));
                        }
                        if (title != null && title.length > MAX_NOTE_TITLE_LENGTH) {
                            return format_tool_error (id_node, "Title exceeds maximum length of %d characters.".printf (MAX_NOTE_TITLE_LENGTH));
                        }

                        var raw_json = proxy.update_note (note_id, title, content, theme);
                        return format_tool_success (id_node, raw_json);
                    }

                    case "delete_note": {
                        var note_id = args_obj.get_string_member_with_default ("id", "");
                        if (note_id == "") {
                            return format_error (id_node, -32602, "Invalid params: 'id' is required");
                        }
                        bool ok = proxy.delete_note (note_id);
                        return format_tool_success (id_node, ok ? "true" : "false");
                    }

                    case "search_notes": {
                        var query = args_obj.get_string_member_with_default ("query", "");
                        if (query.length > MAX_NOTE_TITLE_LENGTH) {
                            return format_tool_error (id_node, "Search query exceeds maximum length of %d characters.".printf (MAX_NOTE_TITLE_LENGTH));
                        }
                        var raw_json = proxy.search_notes (query);
                        return format_tool_success (id_node, raw_json);
                    }

                    default:
                        return format_error (id_node, -32601, "Unknown tool: " + tool_name);
                }
            } catch (GLib.Error e) {
                return format_tool_error (id_node, e.message);
            }
        }

        private string handle_resources_list (Json.Node? id_node) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("resources");
            builder.begin_array ();

            builder.begin_object ();
            builder.set_member_name ("uri");
            builder.add_string_value ("jots://notes");
            builder.set_member_name ("name");
            builder.add_string_value ("All Sticky Notes Overview");
            builder.set_member_name ("mimeType");
            builder.add_string_value ("text/markdown");
            builder.end_object ();

            builder.begin_object ();
            builder.set_member_name ("uri");
            builder.add_string_value ("jots://formatting-guide");
            builder.set_member_name ("name");
            builder.add_string_value ("Jots Markdown Formatting Guide");
            builder.set_member_name ("mimeType");
            builder.add_string_value ("text/markdown");
            builder.end_object ();

            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            return generator_to_string (builder);
        }

        private string handle_resources_read (Json.Node? id_node, Json.Object? params_obj) {
            if (params_obj == null) {
                return format_error (id_node, -32602, "Invalid params: missing parameters object");
            }
            var uri = params_obj.get_string_member_with_default ("uri", "");
            if (uri == "") {
                return format_error (id_node, -32602, "Invalid params: 'uri' is required");
            }

            if (uri == "jots://formatting-guide") {
                string guide_content = "# Jots Markdown Formatting Guide\n\n"
                    + "Jots supports native real-time inline Markdown styling on desktop sticky notes.\n\n"
                    + "## Supported Elements\n\n"
                    + "### 1. Headings\n"
                    + "- `# Heading 1` (large scaled title, bold)\n"
                    + "- `## Heading 2` (medium scaled section, bold)\n"
                    + "- `### Heading 3` (subsection, bold)\n\n"
                    + "### 2. Checklists & Lists\n"
                    + "- `- [ ] Pending action item`\n"
                    + "- `- [x] Completed action item` (rendered with strikethrough)\n"
                    + "- `- Bullet item` or `* Bullet item`\n\n"
                    + "### 3. Text Emphasis\n"
                    + "- `**Bold text**` or `__Bold text__`\n"
                    + "- `*Italic text*` or `_Italic text_`\n"
                    + "- `~~Strikethrough text~~`\n\n"
                    + "### 4. Code & Blocks\n"
                    + "- `` `inline_code()` `` (monospace font)\n"
                    + "- Code blocks with triple backticks\n"
                    + "- `> Blockquote quote text`\n\n"
                    + "### 5. Links\n"
                    + "- `[Link Label](https://example.com)` (rendered as clickable hyperlink)\n\n"
                    + "## Best Practices for AI Assistants\n"
                    + "- Keep note titles concise (max 120 chars).\n"
                    + "- Use checklists (`- [ ]`) for todo items so users can interactively mark them complete.\n"
                    + "- Select appropriate pastel themes: `mint`/`lime` for tasks, `banana` for reminders, `strawberry`/`bubblegum` for urgent items, `blueberry`/`slate` for general notes.\n";

                var builder = new Json.Builder ();
                builder.begin_object ();
                builder.set_member_name ("jsonrpc");
                builder.add_string_value ("2.0");
                add_id_to_builder (builder, id_node);

                builder.set_member_name ("result");
                builder.begin_object ();
                builder.set_member_name ("contents");
                builder.begin_array ();

                builder.begin_object ();
                builder.set_member_name ("uri");
                builder.add_string_value (uri);
                builder.set_member_name ("mimeType");
                builder.add_string_value ("text/markdown");
                builder.set_member_name ("text");
                builder.add_string_value (guide_content);
                builder.end_object ();

                builder.end_array ();
                builder.end_object ();
                builder.end_object ();

                return generator_to_string (builder);
            }

            if (proxy == null) {
                return format_error (id_node, -32603, "Could not connect to Jots D-Bus service.");
            }

            try {
                string text_content = "";
                if (uri == "jots://notes") {
                    var raw_json = proxy.list_notes ();
                    text_content = "# Jots Sticky Notes Overview\n\n" + raw_json;
                } else if (uri.has_prefix ("jots://notes/")) {
                    var note_id = uri.substring ("jots://notes/".length);
                    var raw_json = proxy.get_note (note_id);
                    text_content = raw_json;
                } else {
                    return format_error (id_node, -32602, "Resource not found: " + uri);
                }

                var builder = new Json.Builder ();
                builder.begin_object ();
                builder.set_member_name ("jsonrpc");
                builder.add_string_value ("2.0");
                add_id_to_builder (builder, id_node);

                builder.set_member_name ("result");
                builder.begin_object ();
                builder.set_member_name ("contents");
                builder.begin_array ();

                builder.begin_object ();
                builder.set_member_name ("uri");
                builder.add_string_value (uri);
                builder.set_member_name ("mimeType");
                builder.add_string_value ("text/markdown");
                builder.set_member_name ("text");
                builder.add_string_value (text_content);
                builder.end_object ();

                builder.end_array ();
                builder.end_object ();
                builder.end_object ();

                return generator_to_string (builder);
            } catch (GLib.Error e) {
                return format_error (id_node, -32603, e.message);
            }
        }

        private string handle_prompts_list (Json.Node? id_node) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("prompts");
            builder.begin_array ();

            // prompt: create_action_items
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("create_action_items");
            builder.set_member_name ("description");
            builder.add_string_value ("Create a formatted sticky note from action items.");
            builder.set_member_name ("arguments");
            builder.begin_array ();
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("items");
            builder.set_member_name ("description");
            builder.add_string_value ("Markdown list of action items");
            builder.set_member_name ("required");
            builder.add_boolean_value (true);
            builder.end_object ();
            builder.end_array ();
            builder.end_object ();

            // prompt: summarize_notes
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("summarize_notes");
            builder.set_member_name ("description");
            builder.add_string_value ("Prompt to summarize all current desktop sticky notes.");
            builder.end_object ();

            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            return generator_to_string (builder);
        }

        private string handle_prompts_get (Json.Node? id_node, Json.Object? params_obj) {
            if (params_obj == null) {
                return format_error (id_node, -32602, "Invalid params: missing parameters object");
            }
            var prompt_name = params_obj.get_string_member_with_default ("name", "");
            string prompt_text = "";

            if (prompt_name == "create_action_items") {
                var args = params_obj.has_member ("arguments") ? params_obj.get_object_member ("arguments") : null;
                var items = (args != null && args.has_member ("items")) ? args.get_string_member ("items") : "";
                prompt_text = "Please create a new Jots sticky note with theme 'mint' containing the following action items as a markdown checklist:\n\n" + items;
            } else if (prompt_name == "summarize_notes") {
                prompt_text = "Please read all open sticky notes using list_notes and provide a concise summary grouped by theme.";
            } else {
                return format_error (id_node, -32601, "Prompt not found: " + prompt_name);
            }

            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("messages");
            builder.begin_array ();

            builder.begin_object ();
            builder.set_member_name ("role");
            builder.add_string_value ("user");
            builder.set_member_name ("content");
            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("text");
            builder.set_member_name ("text");
            builder.add_string_value (prompt_text);
            builder.end_object ();
            builder.end_object ();

            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            return generator_to_string (builder);
        }

        private string format_tool_success (Json.Node? id_node, string text_result) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("content");
            builder.begin_array ();

            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("text");
            builder.set_member_name ("text");
            builder.add_string_value (text_result);
            builder.end_object ();

            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            return generator_to_string (builder);
        }

        private string format_tool_error (Json.Node? id_node, string error_message) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("result");
            builder.begin_object ();
            builder.set_member_name ("isError");
            builder.add_boolean_value (true);
            builder.set_member_name ("content");
            builder.begin_array ();

            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value ("text");
            builder.set_member_name ("text");
            builder.add_string_value (error_message);
            builder.end_object ();

            builder.end_array ();
            builder.end_object ();
            builder.end_object ();

            return generator_to_string (builder);
        }

        private string format_error (Json.Node? id_node, int code, string message) {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            add_id_to_builder (builder, id_node);

            builder.set_member_name ("error");
            builder.begin_object ();
            builder.set_member_name ("code");
            builder.add_int_value (code);
            builder.set_member_name ("message");
            builder.add_string_value (message);
            builder.end_object ();

            builder.end_object ();

            return generator_to_string (builder);
        }

        private void add_id_to_builder (Json.Builder builder, Json.Node? id_node) {
            builder.set_member_name ("id");
            if (id_node == null) {
                builder.add_null_value ();
            } else if (id_node.get_node_type () == Json.NodeType.VALUE) {
                var val_type = id_node.get_value_type ();
                if (val_type == typeof (int64) || val_type == typeof (int)) {
                    builder.add_int_value (id_node.get_int ());
                } else if (val_type == typeof (string)) {
                    builder.add_string_value (id_node.get_string ());
                } else {
                    builder.add_null_value ();
                }
            } else {
                builder.add_null_value ();
            }
        }

        private string generator_to_string (Json.Builder builder) {
            var gen = new Json.Generator ();
            gen.set_root (builder.get_root ());
            return gen.to_data (null);
        }
    }
}
