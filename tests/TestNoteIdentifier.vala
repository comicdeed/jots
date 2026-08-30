/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_note_identifier_tests () {
        /**
         * UC-20.15.10: Existing identifier is preserved exactly.
         */
        GLib.Test.add_func ("/NoteIdentifier/UC_20_15_10/PreserveExisting", () => {
            var existing = "my-note~abc123";
            var ensured = Jots.Utils.NoteIdentifier.ensure ("Anything", existing);
            assert_cmpstr (ensured, GLib.CompareOperator.EQ, existing);
        });

        /**
         * UC-20.15.11: Invalid existing identifier is rejected and regenerated.
         */
        GLib.Test.add_func ("/NoteIdentifier/UC_20_15_11/RegenerateInvalidExisting", () => {
            var ensured = Jots.Utils.NoteIdentifier.ensure ("Roadmap", "../../bad");
            var parts = ensured.split ("~");

            assert_cmpint (parts.length, GLib.CompareOperator.EQ, 2);
            assert_cmpstr (parts[0], GLib.CompareOperator.EQ, "roadmap");
            assert_cmpint (parts[1].length, GLib.CompareOperator.EQ, 6);
            assert_false (ensured.contains ("/"));
            assert_false (ensured.contains (".."));
        });

        /**
         * UC-20.15.20: Generated identifier format is slug~token with 6 lowercase alnum chars.
         */
        GLib.Test.add_func ("/NoteIdentifier/UC_20_15_20/GeneratedFormat", () => {
            var ensured = Jots.Utils.NoteIdentifier.ensure ("Roadmap Planning Notes");
            var parts = ensured.split ("~");

            assert_cmpint (parts.length, GLib.CompareOperator.EQ, 2);
            assert_cmpstr (parts[0], GLib.CompareOperator.EQ, "roadmap-planning-notes");
            assert_cmpint (parts[1].length, GLib.CompareOperator.EQ, 6);

            var token = parts[1];
            for (int i = 0; i < token.length; i++) {
                char c = token[i];
                bool is_letter = (c >= 'a' && c <= 'z');
                bool is_digit = (c >= '0' && c <= '9');
                assert_true (is_letter || is_digit);
            }
        });

        /**
         * UC-20.15.30: Slug normalization collapses separators and strips unsupported punctuation.
         */
        GLib.Test.add_func ("/NoteIdentifier/UC_20_15_30/SlugNormalization", () => {
            var ensured = Jots.Utils.NoteIdentifier.ensure ("  Hello___world.." + ". v2!!!  ");
            var parts = ensured.split ("~");

            assert_cmpint (parts.length, GLib.CompareOperator.EQ, 2);
            assert_cmpstr (parts[0], GLib.CompareOperator.EQ, "hello-world-v2");
        });

        /**
         * UC-20.15.40: Empty or punctuation-only titles fall back to note slug.
         */
        GLib.Test.add_func ("/NoteIdentifier/UC_20_15_40/EmptyTitleFallback", () => {
            var ensured = Jots.Utils.NoteIdentifier.ensure (".." + ".___---");
            var parts = ensured.split ("~");

            assert_cmpint (parts.length, GLib.CompareOperator.EQ, 2);
            assert_cmpstr (parts[0], GLib.CompareOperator.EQ, "note");
        });
    }
}
