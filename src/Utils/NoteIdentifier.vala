/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Utils {

    /**
     * Creates and validates stable readable backup identifiers of form slug~token.
     */
    public class NoteIdentifier : Object {

        private const int TOKEN_LENGTH = 6;

        public static string ensure (string title, string? existing = null) {
            if (existing != null && existing.strip () != "") {
                return existing;
            }

            var slug = slugify (title);
            var token = random_token (TOKEN_LENGTH);
            return "%s~%s".printf (slug, token);
        }

        private static string slugify (string title) {
            var input = title.strip ().down ();
            if (input == "") {
                return "note";
            }

            var out_builder = new StringBuilder ();
            bool pending_dash = false;

            for (int i = 0; i < input.length; i++) {
                char c = input[i];
                bool is_letter = (c >= 'a' && c <= 'z');
                bool is_digit = (c >= '0' && c <= '9');

                if (is_letter || is_digit) {
                    if (pending_dash && out_builder.len > 0) {
                        out_builder.append_c ('-');
                    }
                    out_builder.append_c (c);
                    pending_dash = false;
                    continue;
                }

                if (c == ' ' || c == '-' || c == '_' || c == '.') {
                    pending_dash = true;
                }
            }

            var slug = out_builder.str;
            if (slug == "") {
                return "note";
            }

            return slug;
        }

        private static string random_token (int len) {
            const string alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
            var token = new StringBuilder ();

            for (int i = 0; i < len; i++) {
                int idx = Random.int_range (0, alphabet.length);
                token.append_c (alphabet[idx]);
            }

            return token.str;
        }
    }
}
