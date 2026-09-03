/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_git_sync_service_tests () {
        /**
         * UC-80.10.01: Status priorities keep critical states above informational ones.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_01/StatusPriorityOrdering", () => {
            int error_priority = Jots.GitSyncService.status_priority_for (Jots.BACKUP_STATUS_ERROR);
            int diverged_priority = Jots.GitSyncService.status_priority_for (Jots.BACKUP_STATUS_REMOTE_DIVERGED);
            int syncing_priority = Jots.GitSyncService.status_priority_for (Jots.BACKUP_STATUS_SYNCING_REMOTE);
            int ready_priority = Jots.GitSyncService.status_priority_for (Jots.BACKUP_STATUS_REPOSITORY_READY);

            assert_true (error_priority > diverged_priority);
            assert_true (diverged_priority > syncing_priority);
            assert_true (syncing_priority > ready_priority);
        });

        /**
         * UC-80.10.01a: Error status formatting includes summary and optional detail.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_01a/FormatErrorStatus", () => {
            var with_detail = Jots.GitSyncService.format_error_status ("Fetch failed", "network timeout");
            assert_true (with_detail.has_prefix (Jots.BACKUP_STATUS_ERROR + ":"));
            assert_true (with_detail.contains ("Fetch failed"));
            assert_true (with_detail.contains ("network timeout"));

            var without_detail = Jots.GitSyncService.format_error_status ("", "");
            assert_true (without_detail.has_prefix (Jots.BACKUP_STATUS_ERROR + ":"));
            assert_true (without_detail.contains ("Operation failed"));
        });

        /**
         * UC-80.10.01b: Error status formatting preserves valid UTF-8 at truncation boundaries.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_01b/FormatErrorStatusUtf8Boundary", () => {
            var builder = new StringBuilder ();
            for (int i = 0; i < 140; i++) {
                builder.append ("a");
            }
            builder.append ("é");

            var formatted = Jots.GitSyncService.format_error_status ("Remote error", builder.str);
            assert_true (formatted.validate ());
            assert_true (formatted.has_prefix (Jots.BACKUP_STATUS_ERROR + ":"));
        });

        /**
         * UC-80.10.01c: UTF-8 truncation helper preserves character boundaries.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_01c/TruncateUtf8Chars", () => {
            var value = "abéΩz";
            var truncated = Jots.GitSyncService.truncate_utf8_chars (value, 4);
            assert_true (truncated.validate ());
            assert_cmpstr (truncated, GLib.CompareOperator.EQ, "abéΩ");

            var empty = Jots.GitSyncService.truncate_utf8_chars (value, 0);
            assert_cmpstr (empty, GLib.CompareOperator.EQ, "");
        });

        /**
         * UC-80.10.02: Poll status work detector accounts for local and remote in-flight activity.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_02/StatusPollInternalWorkAggregation", () => {
            assert_false (Jots.GitSyncService.has_internal_work_for_status_poll (0, 0, false, false, false));
            assert_true (Jots.GitSyncService.has_internal_work_for_status_poll (1, 0, false, false, false));
            assert_true (Jots.GitSyncService.has_internal_work_for_status_poll (0, 1, false, false, false));
            assert_true (Jots.GitSyncService.has_internal_work_for_status_poll (0, 0, true, false, false));
            assert_true (Jots.GitSyncService.has_internal_work_for_status_poll (0, 0, false, true, false));
            assert_true (Jots.GitSyncService.has_internal_work_for_status_poll (0, 0, false, false, true));
        });

        /**
         * UC-80.10.03: Automatic sync retry cooldown grows exponentially and caps.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_03/AutomaticSyncCooldownBackoff", () => {
            assert_cmpint ((int) Jots.GitSyncService.compute_automatic_retry_cooldown_usec (0), GLib.CompareOperator.EQ, 0);
            assert_cmpint ((int) Jots.GitSyncService.compute_automatic_retry_cooldown_usec (1), GLib.CompareOperator.EQ, 90 * 1000 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.compute_automatic_retry_cooldown_usec (2), GLib.CompareOperator.EQ, 180 * 1000 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.compute_automatic_retry_cooldown_usec (3), GLib.CompareOperator.EQ, 360 * 1000 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.compute_automatic_retry_cooldown_usec (10), GLib.CompareOperator.EQ, 15 * 60 * 1000 * 1000);
        });

        /**
         * UC-80.10.04: Automatic cadence sync respects cooldown boundaries.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_04/AutomaticSyncCooldownGate", () => {
            assert_false (Jots.GitSyncService.should_defer_automatic_sync (1000, 0));
            assert_false (Jots.GitSyncService.should_defer_automatic_sync (1000, 1000));
            assert_true (Jots.GitSyncService.should_defer_automatic_sync (1000, 1001));
            assert_false (Jots.GitSyncService.should_defer_automatic_sync (1500, 1200));
        });

        /**
         * UC-80.10.04a: Automatic sync start gate blocks while any internal work is active.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_04a/AutomaticSyncStartGate", () => {
            assert_true (Jots.GitSyncService.can_start_automatic_remote_sync (true, true, false, 0, 0, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (false, true, false, 0, 0, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (true, false, false, 0, 0, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (true, true, true, 0, 0, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (true, true, false, 1, 0, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (true, true, false, 0, 1, false));
            assert_false (Jots.GitSyncService.can_start_automatic_remote_sync (true, true, false, 0, 0, true));
        });

        /**
         * UC-80.10.05: Cadence values map to expected scheduler intervals.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_05/CadenceIntervalMapping", () => {
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (0), GLib.CompareOperator.EQ, 0);
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (1), GLib.CompareOperator.EQ, 5 * 60 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (2), GLib.CompareOperator.EQ, 15 * 60 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (3), GLib.CompareOperator.EQ, 30 * 60 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (4), GLib.CompareOperator.EQ, 60 * 60 * 1000);
            assert_cmpint ((int) Jots.GitSyncService.cadence_interval_ms_for (99), GLib.CompareOperator.EQ, 0);
        });

        /**
         * UC-80.10.05a: Status arbitration rejects lower-priority transitions unless forced.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_05a/StatusTransitionArbitration", () => {
            assert_true (Jots.GitSyncService.should_accept_status_transition (60, 60, false));
            assert_true (Jots.GitSyncService.should_accept_status_transition (40, 60, false));
            assert_false (Jots.GitSyncService.should_accept_status_transition (90, 60, false));
            assert_true (Jots.GitSyncService.should_accept_status_transition (90, 60, true));
        });

        /**
         * UC-80.10.05b: Timeout parsing uses safe fallback and clamps unreasonable overrides.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_05b/GitTimeoutOverrideParsing", () => {
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds (null, 30), GLib.CompareOperator.EQ, 30);
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds ("", 30), GLib.CompareOperator.EQ, 30);
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds ("0", 30), GLib.CompareOperator.EQ, 30);
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds ("abc", 30), GLib.CompareOperator.EQ, 30);
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds ("3", 30), GLib.CompareOperator.EQ, 3);
            assert_cmpint ((int) Jots.GitSyncService.parse_git_command_timeout_seconds ("999", 30), GLib.CompareOperator.EQ, 300);
        });

        /**
         * UC-80.10.05c: Branch name sanitization rejects unresolved HEAD and whitespace-only values.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_05c/BranchNameSanitization", () => {
            assert_null (Jots.GitSyncService.sanitize_branch_name ("HEAD"));
            assert_null (Jots.GitSyncService.sanitize_branch_name ("   "));
            assert_cmpstr (Jots.GitSyncService.sanitize_branch_name ("main\n"), GLib.CompareOperator.EQ, "main");
            assert_cmpstr (Jots.GitSyncService.sanitize_branch_name (" feature/test "), GLib.CompareOperator.EQ, "feature/test");
        });

        /**
         * UC-80.10.05d: Remote head listings detect content regardless of main/master branch naming.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_05d/RemoteHeadListingDetection", () => {
            assert_false (Jots.GitSyncService.remote_head_listing_has_branch (""));
            assert_false (Jots.GitSyncService.remote_head_listing_has_branch ("origin/HEAD\n"));
            assert_true (Jots.GitSyncService.remote_head_listing_has_branch ("origin/main\n"));
            assert_true (Jots.GitSyncService.remote_head_listing_has_branch ("origin/master\n"));
            assert_true (Jots.GitSyncService.remote_head_listing_has_branch ("origin/HEAD\norigin/main\n"));
        });

        /**
         * UC-80.10.10: Upstream count parser accepts canonical tab-delimited output.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_10/ParseUpstreamCountsTabDelimited", () => {
            int behind = -1;
            int ahead = -1;
            bool parsed = Jots.GitSyncService.try_parse_upstream_counts ("2\t5\n", out behind, out ahead);

            assert_true (parsed);
            assert_cmpint (behind, GLib.CompareOperator.EQ, 2);
            assert_cmpint (ahead, GLib.CompareOperator.EQ, 5);
        });

        /**
         * UC-80.10.20: Upstream count parser accepts irregular whitespace output.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_20/ParseUpstreamCountsWhitespace", () => {
            int behind = -1;
            int ahead = -1;
            bool parsed = Jots.GitSyncService.try_parse_upstream_counts ("  0    12  ", out behind, out ahead);

            assert_true (parsed);
            assert_cmpint (behind, GLib.CompareOperator.EQ, 0);
            assert_cmpint (ahead, GLib.CompareOperator.EQ, 12);
        });

        /**
         * UC-80.10.30: Upstream count parser rejects malformed and non-numeric output.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_30/RejectMalformedCounts", () => {
            int behind = -1;
            int ahead = -1;

            assert_false (Jots.GitSyncService.try_parse_upstream_counts ("", out behind, out ahead));
            assert_false (Jots.GitSyncService.try_parse_upstream_counts ("abc\t3", out behind, out ahead));
            assert_false (Jots.GitSyncService.try_parse_upstream_counts ("-1\t2", out behind, out ahead));
        });

        /**
         * UC-80.10.40: Ephemeral cheat sheet is excluded from sync and ignored in gitignore.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_40/CheatSheetExclusion", () => {
            assert_false (Jots.GitSyncService.should_sync_note (Jots.CHEATSHEET_NOTE_ID));
            assert_true (Jots.GitSyncService.should_sync_note ("3ba7ca8a-d40c-45b9-a9f8-94c15b853e2d"));
            assert_true (Jots.GitSyncService.should_sync_note ("custom-note-uuid"));
            assert_true (Jots.GitSyncService.GITIGNORE_CANONICAL.contains ("jots-cheatsheet.md"));
        });

        /**
         * UC-80.10.50: Rename commit intent captures rename change type and tracks previous origin path.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_50/RenameCommitIntentStructure", () => {
            var intent = new Jots.BackupCommitIntent (
                "new-title~abc123",
                "/notes/new-title~abc123.md",
                false,
                Jots.BackupChangeType.RENAME,
                123456789,
                "old-title~abc123",
                "/notes/old-title~abc123.md"
            );

            assert_true (intent.change_type == Jots.BackupChangeType.RENAME);
            assert_cmpstr (intent.note_id, GLib.CompareOperator.EQ, "new-title~abc123");
            assert_cmpstr (intent.old_note_id, GLib.CompareOperator.EQ, "old-title~abc123");
            assert_cmpstr (intent.note_path, GLib.CompareOperator.EQ, "/notes/new-title~abc123.md");
            assert_cmpstr (intent.old_note_path, GLib.CompareOperator.EQ, "/notes/old-title~abc123.md");
            assert_false (intent.deleted);
        });

        /**
         * UC-80.10.51: Rename commit message formats rename change label clearly.
         */
        GLib.Test.add_func ("/GitSyncService/UC_80_10_51/RenameCommitMessageFormatting", () => {
            var old_id = "meeting-notes~ab12cd";
            var new_id = "sprint-planning~ab12cd";
            var message = "backup(note): rename %s -> %s".printf (old_id, new_id);
            assert_cmpstr (message, GLib.CompareOperator.EQ, "backup(note): rename meeting-notes~ab12cd -> sprint-planning~ab12cd");
        });
    }
}
