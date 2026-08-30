/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_git_sync_service_tests () {
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
    }
}
