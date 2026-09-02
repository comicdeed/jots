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
        private const int MAX_SLUG_LENGTH = 50;
        private const string SAFE_IDENTIFIER_PATTERN = "^[A-Za-z0-9._~-]+$";

        public static string ensure (string? title, string? existing = null) {
            if (existing != null) {
                var candidate = existing.strip ();
                if (is_valid (candidate)) {
                    return candidate;
                }
            }

            var slug = slugify (title);
            var token = random_token (TOKEN_LENGTH);
            return "%s~%s".printf (slug, token);
        }

        public static string update_slug (string? title, string? existing_id) {
            if (existing_id == null || existing_id.strip () == "") {
                return ensure (title, null);
            }

            var candidate = existing_id.strip ();
            if (candidate == CHEATSHEET_NOTE_ID) {
                return CHEATSHEET_NOTE_ID;
            }

            if (!is_valid (candidate)) {
                return ensure (title, null);
            }

            int last_tilde = candidate.last_index_of_char ('~');
            if (last_tilde >= 0 && last_tilde < candidate.length - 1) {
                var token = candidate.substring (last_tilde + 1);
                var slug = slugify (title);
                return "%s~%s".printf (slug, token);
            }

            return candidate;
        }

        public static string extract_token (string? identifier) {
            if (identifier == null) {
                return random_token (TOKEN_LENGTH);
            }
            int last_tilde = identifier.last_index_of_char ('~');
            if (last_tilde >= 0 && last_tilde < identifier.length - 1) {
                var candidate_token = identifier.substring (last_tilde + 1);
                if (is_valid (candidate_token)) {
                    return candidate_token;
                }
            }
            return random_token (TOKEN_LENGTH);
        }

        public static bool is_valid (string? value) {
            if (value == null || value.strip () == "") {
                return false;
            }

            if (value.contains ("/") || value.contains ("\\") || value.contains ("..")) {
                return false;
            }

            return Regex.match_simple (SAFE_IDENTIFIER_PATTERN, value);
        }

        private static string slugify (string? title) {
            if (title == null) {
                return "note";
            }
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
            if (slug.length > MAX_SLUG_LENGTH) {
                slug = slug.substring (0, MAX_SLUG_LENGTH);
                int last_dash = slug.last_index_of_char ('-');
                if (last_dash >= 20) {
                    slug = slug.substring (0, last_dash);
                } else {
                    slug = slug.strip ();
                    while (slug.has_suffix ("-")) {
                        slug = slug.substring (0, slug.length - 1);
                    }
                }
            }

            if (slug == "") {
                return "note";
            }

            return slug;
        }

        private static string random_token (int len) {
            const string ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789";
            var token = new StringBuilder ();

            for (int i = 0; i < len; i++) {
                int idx = Random.int_range (0, ALPHABET.length);
                token.append_c (ALPHABET[idx]);
            }

            return token.str;
        }
    }
}
