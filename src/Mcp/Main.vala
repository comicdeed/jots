/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {
    public class McpMain : GLib.Object {
        private McpProtocol protocol;
        private MainLoop main_loop;
        private DataInputStream stdin_stream;
        private DataOutputStream stdout_stream;
        private NotesProxy? proxy = null;

        public McpMain () {
            protocol = new McpProtocol ();
            main_loop = new MainLoop ();

            var stdin_unix = new UnixInputStream (0, false);
            stdin_stream = new DataInputStream (stdin_unix);

            var stdout_unix = new UnixOutputStream (1, false);
            stdout_stream = new DataOutputStream (stdout_unix);
        }

        public async void start () {
            yield try_connect_dbus ();
            protocol.set_proxy (proxy);

            // Stdio loop
            yield read_next_line ();
        }

        private async void try_connect_dbus () {
            try {
                var conn = yield Bus.get (BusType.SESSION);
                string[] bus_names = {
                    "io.github.comicdeed.jots.devel",
                    "io.github.comicdeed.jots",
                    "io.github.elly_code.jorts"
                };

                string[] object_paths = {
                    "/io/github/comicdeed/jots/devel/Notes",
                    "/io/github/comicdeed/jots/Notes",
                    "/io/github/comicdeed/jots/devel",
                    "/io/github/comicdeed/jots",
                    "/io/github/elly_code/jorts/Notes",
                    "/io/github/elly_code/jorts"
                };

                foreach (var bus_name in bus_names) {
                    foreach (var obj_path in object_paths) {
                        try {
                            var p = yield conn.get_proxy<NotesProxy> (
                                bus_name,
                                obj_path
                            );
                            // Verify responsiveness with ping
                            p.ping ();
                            proxy = p;
                            printerr ("jots-mcp: Connected to D-Bus service at %s (%s)\n", bus_name, obj_path);
                            return;
                        } catch (GLib.Error e) {
                            // continue trying candidates
                        }
                    }
                }
            } catch (GLib.Error e) {
                printerr ("jots-mcp: Warning - D-Bus session bus unavailable: %s\n", e.message);
            }
        }

        private async void read_next_line () {
            try {
                size_t length;
                string? line = yield stdin_stream.read_line_async (Priority.DEFAULT, null, out length);
                if (line == null) {
                    // EOF reached, exit cleanly
                    main_loop.quit ();
                    return;
                }

                // If proxy was not connected initially, attempt reconnect on demand
                if (proxy == null) {
                    yield try_connect_dbus ();
                    protocol.set_proxy (proxy);
                }

                var response = protocol.process_message (line);
                if (response != null) {
                    stdout_stream.put_string (response + "\n");
                    stdout_stream.flush ();
                }

                // Continue reading
                yield read_next_line ();
            } catch (GLib.Error e) {
                printerr ("jots-mcp: I/O error on stdin: %s\n", e.message);
                main_loop.quit ();
            }
        }

        public void run () {
            start.begin ();
            main_loop.run ();
        }

        public static int main (string[] args) {
            var app = new McpMain ();
            app.run ();
            return 0;
        }
    }
}
