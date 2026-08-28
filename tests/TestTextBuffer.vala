/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Dino Korah (github.com/codemedic)
 */

namespace Jots.Tests {
    public void register_text_buffer_tests () {
        /**
         * UC-30.10.10 & UC-30.10.20: Applying and removing list prefixes
         */
        GLib.Test.add_func ("/TextBuffer/UC_30_10_10/ListPrefixApplicationAndRemoval", () => {
            var buffer = new Jots.TextBuffer ();
            buffer.list_item_prefix = "- ";
            buffer.text = "First item\nSecond item\nThird item";

            // Apply list prefix to all lines
            buffer.set_list (0, 2);
            assert_true (buffer.is_list (0, 2));
            assert_true (buffer.has_prefix (0));
            assert_true (buffer.has_prefix (1));
            assert_true (buffer.has_prefix (2));

            // Remove list prefix
            buffer.remove_list (0, 2);
            assert_true (!buffer.is_list (0, 2));
            assert_true (!buffer.has_prefix (0));
            assert_true (!buffer.has_prefix (1));
            assert_true (!buffer.has_prefix (2));
        });

        /**
         * UC-30.10.40: Migrating prefix types across a note
         */
        GLib.Test.add_func ("/TextBuffer/UC_30_10_40/ListPrefixMigration", () => {
            var buffer = new Jots.TextBuffer ();
            buffer.list_item_prefix = "- ";
            buffer.text = "Item Alpha\nItem Beta";
            buffer.set_list (0, 1);

            assert_true (buffer.has_prefix (0));
            assert_true (buffer.text.has_prefix ("- "));

            // User switches prefix in settings to "* "
            buffer.list_item_prefix = "* ";
            assert_true (buffer.has_prefix (0));
            assert_true (buffer.has_prefix (1));
            assert_true (buffer.text.has_prefix ("* "));
        });

        /**
         * UC-30.10.30: Detecting list state
         */
        GLib.Test.add_func ("/TextBuffer/UC_30_10_30/PartialLineListDetection", () => {
            var buffer = new Jots.TextBuffer ();
            buffer.list_item_prefix = "- ";
            buffer.text = "Item 1\nUnprefixed line\nItem 3";

            // Set only first line
            buffer.set_list (0, 0);
            assert_true (buffer.has_prefix (0));
            assert_true (!buffer.has_prefix (1));
            assert_true (!buffer.has_prefix (2));
            assert_true (!buffer.is_list (0, 2));
        });
    }
}
