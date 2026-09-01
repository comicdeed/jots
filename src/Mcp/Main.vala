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
            try {
                while (true) {
                    size_t length;
                    string? line = yield stdin_stream.read_line_async (Priority.DEFAULT, null, out length);
                    if (line == null) {
                        Logger.info ("Client closed stdin stream (EOF reached), exiting.");
                        main_loop.quit ();
                        return;
                    }

                    Logger.trace ("stdin -> " + line);

                    // Only attempt reconnect or auto-spawn when an actual tool or resource action is requested
                    if (proxy == null && is_action_request (line)) {
                        yield ensure_dbus_connection ();
                    }

                    var response = protocol.process_message (line);
                    if (response != null) {
                        Logger.trace ("stdout <- " + response);
                        stdout_stream.put_string (response + "\n");
                        stdout_stream.flush ();
                    }
                }
            } catch (GLib.Error e) {
                Logger.error ("I/O error on stdin: " + e.message);
                main_loop.quit ();
            }
        }

        private struct ServiceCandidate {
            public string bus_name;
            public string object_path;
        }

        private async void try_connect_dbus (bool allow_auto_start = false) {
            try {
                var conn = yield Bus.get (BusType.SESSION);
                ServiceCandidate[] candidates = {
                    { "io.github.comicdeed.jots", "/io/github/comicdeed/jots/Notes" },
                    { "io.github.comicdeed.jots.devel", "/io/github/comicdeed/jots/devel/Notes" },
                    { "io.github.comicdeed.jots", "/io/github/comicdeed/jots" },
                    { "io.github.comicdeed.jots.devel", "/io/github/comicdeed/jots/devel" },
                    { "io.github.elly_code.jorts", "/io/github/elly_code/jorts/Notes" }
                };

                var flags = allow_auto_start ? DBusProxyFlags.NONE : DBusProxyFlags.DO_NOT_AUTO_START;

                foreach (var candidate in candidates) {
                    try {
                        var p = yield conn.get_proxy<NotesProxy> (
                            candidate.bus_name,
                            candidate.object_path,
                            flags
                        );
                        // Verify responsiveness with ping
                        p.ping ();
                        proxy = p;
                        Logger.info ("Connected to D-Bus service at %s (%s)".printf (candidate.bus_name, candidate.object_path));
                        return;
                    } catch (GLib.Error e) {
                        Logger.debug ("Candidate %s (%s) not responsive: %s".printf (candidate.bus_name, candidate.object_path, e.message));
                    }
                }
            } catch (GLib.Error e) {
                Logger.warn ("D-Bus session bus unavailable: " + e.message);
            }
        }

        private async void sleep_async (uint ms) {
            GLib.Timeout.add (ms, () => {
                sleep_async.callback ();
                return GLib.Source.REMOVE;
            });
            yield;
        }

        private static bool is_action_request (string line) {
            var trimmed = line.strip ();
            if (trimmed.contains ("\"tools/call\"")) {
                return true;
            }
            if (trimmed.contains ("\"resources/read\"")) {
                // Static resources (instructions, formatting-guide) do not need D-Bus or GUI activation
                if (trimmed.contains ("jots://instructions") || trimmed.contains ("jots://formatting-guide")) {
                    return false;
                }
                return true;
            }
            return false;
        }

        private async void ensure_dbus_connection () {
            if (proxy != null) {
                return;
            }

            yield try_connect_dbus (false);
            if (proxy != null) {
                protocol.set_proxy (proxy);
                return;
            }


            var ctx = PackagingContext.detect ();
            if (ctx.can_auto_spawn ()) {
                var spawn_cmd = ctx.get_spawn_command (APP_ID);
                if (spawn_cmd != null && spawn_cmd.strip () != "") {
                    try {
                        Logger.info ("Auto-spawning desktop application via '%s'…".printf (spawn_cmd));
                        string[] spawn_argv;
                        Shell.parse_argv (spawn_cmd, out spawn_argv);
                        Process.spawn_async (
                            null,
                            spawn_argv,
                            null,
                            SpawnFlags.SEARCH_PATH | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL,
                            null,
                            null
                        );

                        // Poll D-Bus registration asynchronously up to 2.5s (100 x 25ms)
                        const int MAX_ATTEMPTS = 100;
                        const uint INTERVAL_MS = 25;
                        for (int i = 0; i < MAX_ATTEMPTS; i++) {
                            yield sleep_async (INTERVAL_MS);
                            yield try_connect_dbus (false);
                            if (proxy != null) {
                                protocol.set_proxy (proxy);
                                Logger.info ("Successfully connected to auto-spawned application after %d ms".printf ((i + 1) * (int)INTERVAL_MS));
                                return;
                            }
                        }
                        Logger.warn ("Auto-spawned application via '%s', but D-Bus service was not ready within 2.5s".printf (spawn_cmd));
                        protocol.set_last_error_detail ("Auto-spawned application via '%s', but D-Bus service was not ready within 2.5s.".printf (spawn_cmd));
                    } catch (GLib.Error e) {
                        Logger.error ("Failed to auto-spawn '%s': %s".printf (spawn_cmd, e.message));
                        protocol.set_last_error_detail ("Failed to auto-spawn '%s': %s".printf (spawn_cmd, e.message));
                    }
                }
            }
        }


        public void run () {
            start.begin ();
            main_loop.run ();
        }

        public static int main (string[] args) {
            var level = LogLevel.INFO;
            foreach (var arg in args) {
                if (arg == "--debug" || arg == "-v") {
                    level = LogLevel.DEBUG;
                } else if (arg == "--trace" || arg == "-vv" || arg == "--verbose") {
                    level = LogLevel.TRACE;
                }
            }
            Logger.init (level, null, "jots-mcp");
            Logger.info ("Server initialized (version %s)".printf (McpProtocol.SERVER_VERSION));

            var app = new McpMain ();
            app.run ();
            return 0;
        }
    }
}
