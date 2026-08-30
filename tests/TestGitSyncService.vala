/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_git_sync_service_tests () {
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
