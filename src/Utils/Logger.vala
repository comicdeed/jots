/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots {

    public enum LogLevel {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        DEBUG = 4,
        TRACE = 5;

        public static LogLevel from_string (string str) {
            switch (str.strip ().down ()) {
                case "error":
                    return ERROR;
                case "warn":
                case "warning":
                    return WARN;
                case "debug":
                    return DEBUG;
                case "trace":
                    return TRACE;
                default:
                    return INFO;
            }
        }

        public string to_string () {
            switch (this) {
                case ERROR:
                    return "ERROR";
                case WARN:
                    return "WARN";
                case INFO:
                    return "INFO";
                case DEBUG:
                    return "DEBUG";
                case TRACE:
                    return "TRACE";
                default:
                    return "INFO";
            }
        }
    }

    /**
     * Dedicated, zero-GTK leveled logger for Jots.
     * Streams diagnostic output to stderr (safely isolated from stdout JSON-RPC)
     * and persists log entries to $XDG_CACHE_HOME/jots/<tag>.log across all packaging tiers.
     */
    public class Logger : GLib.Object {
        private static LogLevel current_level = LogLevel.INFO;
        private static FileStream? log_stream = null;
        private static string? log_file_path = null;
        private static string log_tag = "jots";
        private static GLib.Mutex log_mutex = GLib.Mutex ();
        private static bool initialized = false;

        private const int64 MAX_LOG_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
        private const int MAX_ROTATED_FILES = 3;

        private static void rotate_logs (string base_path) {
            try {
                // Delete oldest backup if it exists (e.g. .3)
                var oldest = "%s.%d".printf (base_path, MAX_ROTATED_FILES);
                if (FileUtils.test (oldest, FileTest.EXISTS)) {
                    FileUtils.unlink (oldest);
                }

                // Cascade shift existing backups (.2 -> .3, .1 -> .2)
                for (int i = MAX_ROTATED_FILES - 1; i >= 1; i--) {
                    var src = "%s.%d".printf (base_path, i);
                    var dst = "%s.%d".printf (base_path, i + 1);
                    if (FileUtils.test (src, FileTest.EXISTS)) {
                        FileUtils.rename (src, dst);
                    }
                }

                // Rotate current active log to .1
                var first_backup = base_path + ".1";
                FileUtils.rename (base_path, first_backup);
            } catch (GLib.Error e) {
                printerr ("jots: Warning during log rotation: %s\n", e.message);
            }
        }

        public static void init (LogLevel initial_level = LogLevel.INFO, string? custom_path = null, string tag = "jots") {
            log_mutex.lock ();
            current_level = initial_level;
            log_tag = tag;

            // Environment overrides
            var env_level = Environment.get_variable ("JOTS_LOG_LEVEL");
            if (env_level != null && env_level.strip () != "") {
                current_level = LogLevel.from_string (env_level);
            }

            var g_debug = Environment.get_variable ("G_MESSAGES_DEBUG");
            if (g_debug != null && (g_debug.contains ("jots") || g_debug.contains ("all"))) {
                if (current_level < LogLevel.DEBUG) {
                    current_level = LogLevel.DEBUG;
                }
            }

            if (custom_path != null || !initialized) {
                try {
                    var env_file = Environment.get_variable ("JOTS_LOG_FILE");
                    if (custom_path != null) {
                        log_file_path = custom_path;
                    } else if (env_file != null && env_file.strip () != "") {
                        log_file_path = env_file.strip ();
                    } else if (log_file_path == null) {
                        var base_cache = Environment.get_variable ("XDG_CACHE_HOME");
                        if (base_cache == null || base_cache.strip () == "" || base_cache.contains ("AppImage-Cache")) {
                            base_cache = Path.build_filename (Environment.get_home_dir (), ".cache");
                        }
                        var cache_dir = Path.build_filename (base_cache, "jots");
                        var filename = (tag == "jots-mcp" || tag == "mcp") ? "mcp.log" : "jots.log";
                        log_file_path = Path.build_filename (cache_dir, filename);
                    }

                    if (log_file_path != null) {
                        var parent_dir = Path.get_dirname (log_file_path);
                        if (parent_dir != null && parent_dir != "") {
                            var parent_folder = GLib.File.new_for_path (parent_dir);
                            if (!parent_folder.query_exists ()) {
                                parent_folder.make_directory_with_parents ();
                            }
                        }

                        // Check log rotation
                        var file = GLib.File.new_for_path (log_file_path);
                        if (file.query_exists ()) {
                            var info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                            if (info != null && info.get_size () > MAX_LOG_SIZE_BYTES) {
                                rotate_logs (log_file_path);
                            }
                        }

                        if (log_stream != null) {
                            log_stream = null;
                        }
                        log_stream = FileStream.open (log_file_path, "a");
                        if (log_stream == null) {
                            printerr ("%s: Warning - Could not open log file at '%s'\n", tag, log_file_path);
                        } else {
                            if (current_level >= LogLevel.DEBUG) {
                                printerr ("%s: Persistent log initialized at '%s'\n", tag, log_file_path);
                            }
                        }
                    }
                } catch (GLib.Error e) {
                    printerr ("%s: Warning - Could not initialize log file: %s\n", tag, e.message);
                }
            }

            initialized = true;
            log_mutex.unlock ();
        }

        public static LogLevel get_level () {
            log_mutex.lock ();
            var lvl = current_level;
            log_mutex.unlock ();
            return lvl;
        }

        public static void set_level (LogLevel level) {
            log_mutex.lock ();
            current_level = level;
            log_mutex.unlock ();
        }

        public static string? get_log_path () {
            log_mutex.lock ();
            var path = log_file_path;
            log_mutex.unlock ();
            return path;
        }

        public static void error (string message) {
            log (LogLevel.ERROR, message);
        }

        public static void warn (string message) {
            log (LogLevel.WARN, message);
        }

        public static void info (string message) {
            log (LogLevel.INFO, message);
        }

        public static void debug (string message) {
            log (LogLevel.DEBUG, message);
        }

        public static void trace (string message) {
            log (LogLevel.TRACE, message);
        }

        public static void log (LogLevel level, string message) {
            log_mutex.lock ();
            if (!initialized) {
                log_mutex.unlock ();
                init ();
                log_mutex.lock ();
            }

            if (level > current_level) {
                log_mutex.unlock ();
                return;
            }

            var now = new DateTime.now_local ();
            var timestamp = "%s.%03d".printf (
                now.format ("%Y-%m-%d %H:%M:%S"),
                (int)(now.get_microsecond () / 1000)
            );

            var line = "[%s] [%s] [%s] %s\n".printf (timestamp, level.to_string (), log_tag, message);

            // 1. Output strictly to stderr (protecting stdout JSON-RPC)
            printerr ("%s", line);

            // 2. Append to persistent log file
            if (log_stream != null) {
                log_stream.puts (line);
                log_stream.flush ();
            }
            log_mutex.unlock ();
        }
    }
}
