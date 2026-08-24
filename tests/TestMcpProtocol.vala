/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {
    /**
     * Mock D-Bus NotesProxy for unit testing MCP protocol routing and validation.
     */
    public class MockNotesProxy : GLib.Object, Jots.NotesProxy {
        public string last_created_title = "";
        public string last_created_content = "";
        public string last_created_theme = "";
        public string last_updated_id = "";
        public string last_deleted_id = "";
        public string last_searched_query = "";

        public string list_notes () throws GLib.Error {
            return "[{\"id\":\"test-uuid-1\",\"title\":\"Mock Note\",\"theme\":\"mint\",\"content_length\":25,\"monospace\":false}]";
        }

        public string get_note (string id) throws GLib.Error {
            if (id == "nonexistent") {
                throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
            }
            return "{\"id\":\"" + id + "\",\"title\":\"Mock Note\",\"content\":\"Hello World\",\"theme\":\"mint\",\"monospace\":false,\"zoom\":100,\"width\":300,\"height\":300}";
        }

        public string create_note (string? title, string? content, string? theme) throws GLib.Error {
            this.last_created_title = title ?? "";
            this.last_created_content = content ?? "";
            this.last_created_theme = theme ?? "blueberry";

            return "{\"id\":\"new-mock-uuid\",\"title\":\"" + last_created_title + "\",\"content\":\"" + last_created_content + "\",\"theme\":\"" + last_created_theme + "\",\"monospace\":false,\"zoom\":100,\"width\":300,\"height\":300}";
        }

        public string update_note (string id, string? title, string? content, string? theme) throws GLib.Error {
            if (id == "nonexistent") {
                throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
            }
            this.last_updated_id = id;
            return "{\"id\":\"" + id + "\",\"title\":\"Updated Title\",\"content\":\"Updated Content\",\"theme\":\"mint\",\"monospace\":false,\"zoom\":100,\"width\":300,\"height\":300}";
        }

        public bool delete_note (string id) throws GLib.Error {
            if (id == "nonexistent") {
                throw new GLib.IOError.NOT_FOUND ("Note with ID '%s' was not found.", id);
            }
            this.last_deleted_id = id;
            return true;
        }

        public string search_notes (string query) throws GLib.Error {
            this.last_searched_query = query;
            return "[{\"id\":\"search-match-1\",\"title\":\"Match\",\"theme\":\"lime\",\"content_length\":10,\"monospace\":false}]";
        }

        public string ping () throws GLib.Error {
            return "pong";
        }
    }

    public void register_mcp_protocol_tests () {
        /**
         * UC-70.10.10: MCP Handshake & initialize response
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_10_10/InitializeHandshake", () => {
            var protocol = new Jots.McpProtocol (null);
            var req = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\"}}";
            var resp = protocol.process_message (req);

            assert_true (resp != null);
            assert_true (resp.contains ("\"jsonrpc\":\"2.0\""));
            assert_true (resp.contains ("\"protocolVersion\":\"2024-11-05\""));
            assert_true (resp.contains ("\"name\":\"jots\""));
            assert_true (resp.contains ("\"version\":\"4.3.0\""));
            assert_true (resp.contains ("\"tools\""));
            assert_true (resp.contains ("\"resources\""));
            assert_true (resp.contains ("\"prompts\""));
        });

        /**
         * UC-70.10.20: MCP Ping tool
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_10_20/Ping", () => {
            var protocol = new Jots.McpProtocol (null);
            var req = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"ping\"}";
            var resp = protocol.process_message (req);

            assert_true (resp != null);
            assert_true (resp.contains ("\"jsonrpc\":\"2.0\""));
            assert_true (resp.contains ("\"id\":2"));
            assert_true (resp.contains ("\"result\":{}"));
        });

        /**
         * UC-70.10.30: MCP Tools Discovery (tools/list)
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_10_30/ToolsList", () => {
            var protocol = new Jots.McpProtocol (null);
            var req = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/list\"}";
            var resp = protocol.process_message (req);

            assert_true (resp != null);
            assert_true (resp.contains ("list_notes"));
            assert_true (resp.contains ("read_note"));
            assert_true (resp.contains ("create_note"));
            assert_true (resp.contains ("update_note"));
            assert_true (resp.contains ("delete_note"));
            assert_true (resp.contains ("search_notes"));
            assert_true (resp.contains ("10,000 chars"));
            assert_true (resp.contains ("120 chars"));
        });

        /**
         * UC-70.10.40: MCP Notifications produce no response
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_10_40/NotificationsIgnored", () => {
            var protocol = new Jots.McpProtocol (null);
            var req = "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}";
            var resp = protocol.process_message (req);

            assert_true (resp == null);
        });

        /**
         * UC-70.10.50: MCP Error formatting for invalid methods and parse errors
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_10_50/ErrorHandling", () => {
            var protocol = new Jots.McpProtocol (null);

            // Unknown method
            var req_unknown = "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"nonexistent/method\"}";
            var resp_unknown = protocol.process_message (req_unknown);
            assert_true (resp_unknown != null);
            assert_true (resp_unknown.contains ("\"code\":-32601"));

            // Parse error
            var req_bad = "{invalid json}";
            var resp_bad = protocol.process_message (req_bad);
            assert_true (resp_bad != null);
            assert_true (resp_bad.contains ("\"code\":-32700"));
        });

        /**
         * UC-70.20.10: String vs Integer vs UUID JSON-RPC IDs
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_20_10/StringAndIntegerIds", () => {
            var protocol = new Jots.McpProtocol (null);

            // Integer ID
            var resp_int = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":42,\"method\":\"ping\"}");
            assert_true (resp_int.contains ("\"id\":42"));

            // String ID (UUID style)
            var resp_str = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"req-abc-789\",\"method\":\"ping\"}");
            assert_true (resp_str.contains ("\"id\":\"req-abc-789\""));
        });

        /**
         * UC-70.20.20: End-to-end Tools Call Routing with MockProxy
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_20_20/ToolsCallRouting", () => {
            var mock = new MockNotesProxy ();
            var protocol = new Jots.McpProtocol (mock);

            // 1. list_notes
            var resp_list = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"tools/call\",\"params\":{\"name\":\"list_notes\",\"arguments\":{}}}");
            assert_true (resp_list != null);
            assert_true (resp_list.contains ("test-uuid-1"));
            assert_true (resp_list.contains ("Mock Note"));

            // 2. read_note
            var resp_read = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"2\",\"method\":\"tools/call\",\"params\":{\"name\":\"read_note\",\"arguments\":{\"id\":\"test-uuid-1\"}}}");
            assert_true (resp_read != null);
            assert_true (resp_read.contains ("Hello World"));

            // 3. create_note
            var resp_create = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"3\",\"method\":\"tools/call\",\"params\":{\"name\":\"create_note\",\"arguments\":{\"title\":\"Shopping\",\"content\":\"Milk, Bread\",\"theme\":\"banana\"}}}");
            assert_true (resp_create != null);
            assert_cmpstr (mock.last_created_title, GLib.CompareOperator.EQ, "Shopping");
            assert_cmpstr (mock.last_created_content, GLib.CompareOperator.EQ, "Milk, Bread");
            assert_cmpstr (mock.last_created_theme, GLib.CompareOperator.EQ, "banana");

            // 4. update_note
            var resp_update = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"4\",\"method\":\"tools/call\",\"params\":{\"name\":\"update_note\",\"arguments\":{\"id\":\"test-uuid-1\",\"title\":\"New Title\"}}}");
            assert_true (resp_update != null);
            assert_cmpstr (mock.last_updated_id, GLib.CompareOperator.EQ, "test-uuid-1");

            // 5. delete_note
            var resp_delete = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"5\",\"method\":\"tools/call\",\"params\":{\"name\":\"delete_note\",\"arguments\":{\"id\":\"test-uuid-1\"}}}");
            assert_true (resp_delete != null);
            assert_true (resp_delete.contains ("true"));
            assert_cmpstr (mock.last_deleted_id, GLib.CompareOperator.EQ, "test-uuid-1");

            // 6. search_notes
            var resp_search = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"6\",\"method\":\"tools/call\",\"params\":{\"name\":\"search_notes\",\"arguments\":{\"query\":\"urgent\"}}}");
            assert_true (resp_search != null);
            assert_cmpstr (mock.last_searched_query, GLib.CompareOperator.EQ, "urgent");
            assert_true (resp_search.contains ("search-match-1"));
        });

        /**
         * UC-70.30.10: Complex Unicode, Multiline Markdown, Quotes & Emoji Payloads
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_30_10/UnicodeAndMarkdownPayloads", () => {
            var mock = new MockNotesProxy ();
            var protocol = new Jots.McpProtocol (mock);

            // Multiline markdown with code blocks, quotes, and international characters
            var title = "🚀 Release Plan 日本語 & العربية";
            var content = "## Actions\n* [x] Deploy to Flathub ✨\n* [ ] Check `io.github.comicdeed.jots`\n\n```python\nprint(\"Hello \\\"World\\\"\")\n```";

            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("jsonrpc");
            builder.add_string_value ("2.0");
            builder.set_member_name ("id");
            builder.add_string_value ("unicode-test");
            builder.set_member_name ("method");
            builder.add_string_value ("tools/call");

            builder.set_member_name ("params");
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value ("create_note");
            builder.set_member_name ("arguments");
            builder.begin_object ();
            builder.set_member_name ("title");
            builder.add_string_value (title);
            builder.set_member_name ("content");
            builder.add_string_value (content);
            builder.set_member_name ("theme");
            builder.add_string_value ("grape");
            builder.end_object ();
            builder.end_object ();
            builder.end_object ();

            var gen = new Json.Generator ();
            gen.set_root (builder.get_root ());
            var req_json = gen.to_data (null);

            var resp = protocol.process_message (req_json);
            assert_true (resp != null);
            assert_cmpstr (mock.last_created_title, GLib.CompareOperator.EQ, title);
            assert_cmpstr (mock.last_created_content, GLib.CompareOperator.EQ, content);
            assert_cmpstr (mock.last_created_theme, GLib.CompareOperator.EQ, "grape");
        });

        /**
         * UC-70.40.10: Guardrail Boundary Conditions (10,000 chars content, 120 chars title)
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_40_10/GuardrailBoundaryConditions", () => {
            var mock = new MockNotesProxy ();
            var protocol = new Jots.McpProtocol (mock);

            // 1. Content exactly at boundary: 10,000 characters
            var exactly_10000 = string.nfill (10000, 'A');
            var resp_exact = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"tools/call\",\"params\":{\"name\":\"create_note\",\"arguments\":{\"title\":\"Boundary\",\"content\":\"" + exactly_10000 + "\"}}}");
            assert_true (resp_exact != null);
            assert_true (!resp_exact.contains ("\"isError\":true"));
            assert_cmpint ((int) mock.last_created_content.length, GLib.CompareOperator.EQ, 10000);

            // 2. Content over boundary: 10,001 characters -> Must return isError: true
            var over_10000 = string.nfill (10001, 'B');
            var resp_over = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"2\",\"method\":\"tools/call\",\"params\":{\"name\":\"create_note\",\"arguments\":{\"title\":\"Over\",\"content\":\"" + over_10000 + "\"}}}");
            assert_true (resp_over != null);
            assert_true (resp_over.contains ("\"isError\":true"));
            assert_true (resp_over.contains ("exceeds maximum length"));

            // 3. Title over boundary: 121 characters -> Must return isError: true
            var over_title = string.nfill (121, 'T');
            var resp_over_title = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"3\",\"method\":\"tools/call\",\"params\":{\"name\":\"create_note\",\"arguments\":{\"title\":\"" + over_title + "\",\"content\":\"Short\"}}}");
            assert_true (resp_over_title != null);
            assert_true (resp_over_title.contains ("\"isError\":true"));
            assert_true (resp_over_title.contains ("Title exceeds maximum length"));
        });

        /**
         * UC-70.50.10: Resources & Prompts Handlers
         */
        GLib.Test.add_func ("/McpProtocol/UC_70_50_10/ResourcesAndPrompts", () => {
            var mock = new MockNotesProxy ();
            var protocol = new Jots.McpProtocol (mock);

            // resources/list
            var resp_res_list = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"resources/list\"}");
            assert_true (resp_res_list.contains ("jots://notes"));
            assert_true (resp_res_list.contains ("jots://formatting-guide"));

            // resources/read for jots://notes
            var resp_res_read = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"2\",\"method\":\"resources/read\",\"params\":{\"uri\":\"jots://notes\"}}");
            assert_true (resp_res_read.contains ("# Jots Sticky Notes Overview"));
            assert_true (resp_res_read.contains ("test-uuid-1"));

            // resources/read for jots://formatting-guide
            var resp_guide_read = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"guide-1\",\"method\":\"resources/read\",\"params\":{\"uri\":\"jots://formatting-guide\"}}");
            assert_true (resp_guide_read.contains ("# Jots Markdown Formatting Guide"));
            assert_true (resp_guide_read.contains ("Checklists & Lists"));

            // prompts/list
            var resp_prompts_list = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"3\",\"method\":\"prompts/list\"}");
            assert_true (resp_prompts_list.contains ("create_action_items"));
            assert_true (resp_prompts_list.contains ("summarize_notes"));

            // prompts/get with arguments
            var resp_prompt_get = protocol.process_message ("{\"jsonrpc\":\"2.0\",\"id\":\"4\",\"method\":\"prompts/get\",\"params\":{\"name\":\"create_action_items\",\"arguments\":{\"items\":\"- Buy coffee\\n- Fix bug\"}}}");
            assert_true (resp_prompt_get.contains ("Buy coffee"));
        });
    }
}
