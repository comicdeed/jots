/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2026 Jots Contributors
 */

namespace Jots.Tests {

    public class MockActiveNotesProvider : GLib.Object, Jots.ActiveNotesProvider {
        public Gee.List<NoteData> active_list;

        public MockActiveNotesProvider (Gee.List<NoteData> list) {
            this.active_list = list;
        }

        public Gee.List<NoteData> get_active_notes () {
            return active_list;
        }
    }

    public class TestSearchService {

        public static void register () {
            GLib.Test.add_func ("/SearchService/UC_80_10_10/LiveBufferSearch", test_live_buffer_search);
            GLib.Test.add_func ("/SearchService/UC_80_10_20/ClosedNoteDiskSearch", test_closed_note_disk_search);
            GLib.Test.add_func ("/SearchService/UC_80_10_30/RelevanceScoringAndOrdering", test_relevance_scoring_and_ordering);
            GLib.Test.add_func ("/SearchService/UC_80_10_35/FrequencyScoreBoosting", test_frequency_score_boosting);
            GLib.Test.add_func ("/SearchService/UC_80_10_40/SnippetExtractionAndEscaping", test_snippet_extraction_and_escaping);
            GLib.Test.add_func ("/SearchService/UC_80_10_42/TitleMatchFallbackSnippet", test_title_match_fallback_snippet);
            GLib.Test.add_func ("/SearchService/UC_80_10_45/EntitySubstringQueryNoCorruption", test_entity_substring_query_no_corruption);
            GLib.Test.add_func ("/SearchService/UC_80_10_48/RegexSpecialCharactersQuery", test_regex_special_characters_query);
            GLib.Test.add_func ("/SearchService/UC_80_10_50/MultibyteUnicodeAndCasing", test_multibyte_unicode_and_casing);
            GLib.Test.add_func ("/SearchService/UC_80_10_55/EmptyAndWhitespaceQueries", test_empty_and_whitespace_queries);
            GLib.Test.add_func ("/SearchService/UC_80_10_58/DeduplicationOpenAndDisk", test_deduplication_open_and_disk);
            GLib.Test.add_func ("/SearchService/UC_80_10_60/GuardrailLimits", test_guardrail_limits);
            GLib.Test.add_func ("/SearchService/UC_80_10_70/JsonSerializationOutput", test_json_serialization_output);
        }

        private static string create_temp_notes_dir () {
            var temp_dir = Path.build_filename (Environment.get_tmp_dir (), "jots-search-test-" + GLib.Uuid.string_random ());
            DirUtils.create_with_parents (temp_dir, 0700);
            return temp_dir;
        }

        private static void test_live_buffer_search () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var active_list = new Gee.ArrayList<NoteData> ();
            var note1 = new NoteData () {
                id = "live-open-1",
                title = "Shopping List",
                content = "- [ ] Apples\n- [ ] Milk\n- [ ] Fresh wheat bread (unsaved live edit)",
                theme = Themes.MINT
            };
            active_list.add (note1);

            var provider = new MockActiveNotesProvider (active_list);
            var search_service = new SearchService (storage, provider);

            var results = search_service.search ("wheat");
            assert_true (results.size == 1);
            var res = results.get (0);
            assert_true (res.id == "live-open-1");
            assert_true (res.is_active == true);
            assert_true (res.title == "Shopping List");
            assert_true (res.theme == Themes.MINT);
            assert_true (res.snippet.contains ("<b>wheat</b>"));
        }

        private static void test_closed_note_disk_search () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            var noteA = new NoteData () {
                id = "stored-a",
                title = "Meeting Notes",
                content = "Discuss Q3 quarterly architecture roadmap and milestones",
                theme = Themes.BLUEBERRY
            };
            var noteB = new NoteData () {
                id = "stored-b",
                title = "Recipe Ideas",
                content = "Pasta with garlic and olive oil",
                theme = Themes.BANANA
            };

            storage.save_note (noteA);
            storage.save_note (noteB);

            var results = search_service.search ("quarterly");
            assert_true (results.size == 1);
            assert_true (results.get (0).id == "stored-a");
            assert_true (results.get (0).is_active == false);
            assert_true (results.get (0).snippet.contains ("<b>quarterly</b>"));
        }

        private static void test_relevance_scoring_and_ordering () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            // Note 1 has match in body only
            var note1 = new NoteData () {
                id = "note-body",
                title = "Daily Journal",
                content = "Had a great meeting about architecture today."
            };
            // Note 2 has match in title
            var note2 = new NoteData () {
                id = "note-title",
                title = "Architecture Plan",
                content = "General design principles and patterns."
            };

            storage.save_note (note1);
            storage.save_note (note2);

            var results = search_service.search ("Architecture");
            assert_true (results.size == 2);
            // Note 2 (title match) must be ranked higher than Note 1 (body match)
            assert_true (results.get (0).id == "note-title");
            assert_true (results.get (1).id == "note-body");
            assert_true (results.get (0).score > results.get (1).score);
        }

        private static void test_frequency_score_boosting () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            // Note 1 has 1 occurrence (10 pts)
            var note1 = new NoteData () {
                id = "freq-1",
                title = "Note 1",
                content = "This note mentions keyword once."
            };
            // Note 2 has 4 occurrences (40 pts)
            var note2 = new NoteData () {
                id = "freq-4",
                title = "Note 2",
                content = "keyword keyword keyword keyword in note 2."
            };

            storage.save_note (note1);
            storage.save_note (note2);

            var results = search_service.search ("keyword");
            assert_true (results.size == 2);
            assert_true (results.get (0).id == "freq-4");
            assert_true (results.get (1).id == "freq-1");
            assert_true (results.get (0).score > results.get (1).score);
        }

        private static void test_snippet_extraction_and_escaping () {
            var storage = new Storage ();
            var search_service = new SearchService (storage);

            // Text with special XML characters & and < >
            var text = "Use <tag> & symbols carefully when writing <code> in Markdown.";
            var snippet = search_service.extract_snippet (text, "symbols", "Fallback Title");

            assert_true (snippet.contains ("&amp;"));
            assert_true (snippet.contains ("&lt;tag&gt;"));
            assert_true (snippet.contains ("<b>symbols</b>"));
        }

        private static void test_title_match_fallback_snippet () {
            var storage = new Storage ();
            var search_service = new SearchService (storage);

            // Match in title only: snippet should fall back to first ~90 chars of content
            var content = "This is a body without the search term that gives general context.";
            var snippet = search_service.extract_snippet (content, "nonexistent-in-body", "Fallback Title");

            assert_true (snippet.contains ("This is a body without"));

            // Empty body: snippet should fall back to title
            var snippet_empty = search_service.extract_snippet ("", "nonexistent-in-body", "Fallback Note Title");
            assert_cmpstr (snippet_empty, GLib.CompareOperator.EQ, "Fallback Note Title");
        }

        private static void test_entity_substring_query_no_corruption () {
            var storage = new Storage ();
            var search_service = new SearchService (storage);

            // Text containing XML entities
            var text = "Connecting to AT&T cellular network with <tag> custom markup.";
            // Searching for "amp" or "tag" must not break markup entities
            var snippet_tag = search_service.extract_snippet (text, "tag", "Fallback Title");
            assert_true (snippet_tag.contains ("&lt;<b>tag</b>&gt;"));
            assert_true (snippet_tag.contains ("&amp;"));
            assert_false (snippet_tag.contains ("&<b>amp</b>;"));
        }

        private static void test_regex_special_characters_query () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            var note = new NoteData () {
                id = "regex-note",
                title = "C++ & Regex Tasks",
                content = "- [ ] Fix (parser) bug in C++ code*\n- [x] Complete task"
            };
            storage.save_note (note);

            // Search query with regex special chars: "[ ]"
            var results1 = search_service.search ("- [ ]");
            assert_true (results1.size == 1);
            assert_true (results1.get (0).snippet.contains ("<b>- [ ]</b>"));

            // Search query with parentheses and plus: "C++"
            var results2 = search_service.search ("C++");
            assert_true (results2.size == 1);
            assert_true (results2.get (0).snippet.contains ("<b>C++</b>"));
        }

        private static void test_multibyte_unicode_and_casing () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            var note = new NoteData () {
                id = "unicode-note",
                title = "Café & Résumé 🚀",
                content = "Visiting the gemütlich café in München."
            };
            storage.save_note (note);

            // Search lowercase "café" matches "Café"
            var results1 = search_service.search ("café");
            assert_true (results1.size == 1);
            assert_true (results1.get (0).id == "unicode-note");

            // Search lowercase "münchen" matches "München"
            var results2 = search_service.search ("münchen");
            assert_true (results2.size == 1);
            assert_true (results2.get (0).snippet.contains ("<b>München</b>") || results2.get (0).snippet.contains ("<b>münchen</b>"));
        }

        private static void test_empty_and_whitespace_queries () {
            var storage = new Storage ();
            var search_service = new SearchService (storage);

            var res1 = search_service.search ("");
            assert_true (res1.size == 0);

            var res2 = search_service.search ("   ");
            assert_true (res2.size == 0);
        }

        private static void test_deduplication_open_and_disk () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            // Save note to disk
            var note_disk = new NoteData () {
                id = "shared-uuid",
                title = "Disk Title",
                content = "Saved disk content keyword match"
            };
            storage.save_note (note_disk);

            // Active open note in memory with same ID (live edit)
            var active_list = new Gee.ArrayList<NoteData> ();
            var note_live = new NoteData () {
                id = "shared-uuid",
                title = "Live Title",
                content = "Live memory content keyword match"
            };
            active_list.add (note_live);

            var provider = new MockActiveNotesProvider (active_list);
            var search_service = new SearchService (storage, provider);

            var results = search_service.search ("keyword");
            // Must return exactly 1 result (the live active version)
            assert_true (results.size == 1);
            assert_true (results.get (0).id == "shared-uuid");
            assert_true (results.get (0).is_active == true);
            assert_true (results.get (0).title == "Live Title");
        }

        private static void test_guardrail_limits () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            // Save 30 notes with the keyword "project"
            for (int i = 0; i < 30; i++) {
                var note = new NoteData () {
                    id = "proj-%02d".printf (i),
                    title = "Project Note %d".printf (i),
                    content = "Important project deliverables and timeline."
                };
                storage.save_note (note);
            }

            var results = search_service.search ("project");
            // Must be clamped to MAX_SEARCH_RESULTS (20)
            assert_true (results.size == MAX_SEARCH_RESULTS);
        }

        private static void test_json_serialization_output () {
            var temp_dir = create_temp_notes_dir ();
            var storage = new Storage ();
            storage.override_notes_dir (temp_dir);

            var search_service = new SearchService (storage);

            var note = new NoteData () {
                id = "json-note-1",
                title = "Release Checklist",
                content = "Prepare final binary for flathub deployment.",
                theme = Themes.BLUEBERRY
            };
            storage.save_note (note);

            var json_str = search_service.search_json ("flathub");
            assert_true (json_str.length > 0);
            assert_true (json_str.contains ("json-note-1"));
            assert_true (json_str.contains ("Release Checklist"));
            assert_true (json_str.contains ("blueberry"));
            assert_true (json_str.contains ("score"));
            assert_true (json_str.contains ("<b>flathub</b>"));
        }
    }

    public static void register_search_service_tests () {
        TestSearchService.register ();
    }
}
