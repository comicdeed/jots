#
#   TESTS
#

#========================
# Linter and Appstream validation

vala_linter = find_program('io.elementary.vala-lint', required: false)
if vala_linter.found()
    test('lint',
        vala_linter,
        args: [meson.project_source_root() / 'src'],
        is_parallel: true)
endif

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test('schema',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.project_source_root() / 'data'],
        is_parallel: true)
endif

# Windows cares not for Appstream
if appstream
    desktop_utils = find_program('desktop-file-validate', required: false)
    if desktop_utils.found()
        test('desktop',
            desktop_utils,
            args: [desktop_file],
            is_parallel: true)
    endif

    appstreamcli = find_program('appstreamcli', required: false)
    if appstreamcli.found()
        test('metainfo',
            appstreamcli,
            args: ['validate', '--no-net', '--explain', appstream_file],
            is_parallel: true)
    endif
endif

#========================
# Canary Unit Test Runner

test_sources = files(
    'Main.vala',
    'TestNoteData.vala',
    'TestMarkdownStorage.vala',
    'TestMarkdownBuffer.vala',
    'TestThemes.vala',
    'TestTextBuffer.vala',
    'TestZoom.vala',
    'TestScribblyController.vala',
    'TestMcpProtocol.vala',
    'TestSearchService.vala',
    'TestMigrationHelper.vala',
    'TestCheatSheet.vala',
    'TestAutostart.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'NoteData.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'SearchResult.vala',
    meson.project_source_root() / 'src' / 'Services' / 'MarkdownSerializer.vala',
    meson.project_source_root() / 'src' / 'Services' / 'Storage.vala',
    meson.project_source_root() / 'src' / 'Services' / 'SearchService.vala',
    meson.project_source_root() / 'src' / 'Services' / 'FontController.vala',
    meson.project_source_root() / 'src' / 'Services' / 'ScribblyController.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'Themes.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'Zoom.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'ZoomType.vala',
    meson.project_source_root() / 'src' / 'Objects' / 'ListPrefix.vala',
    meson.project_source_root() / 'src' / 'Widgets' / 'TextBuffer.vala',
    meson.project_source_root() / 'src' / 'Widgets' / 'MarkdownBuffer.vala',
    meson.project_source_root () / 'src' / 'Utils' / 'Random.vala',
    meson.project_source_root () / 'src' / 'Utils' / 'Markup.vala',
    meson.project_source_root () / 'src' / 'Utils' / 'PackagingContext.vala',
    meson.project_source_root () / 'src' / 'Widgets' / 'Bin.vala',
    meson.project_source_root () / 'src' / 'Constants.vala',
    meson.project_source_root () / 'src' / 'Mcp' / 'NotesDbusProxy.vala',
    meson.project_source_root () / 'src' / 'Mcp' / 'McpProtocol.vala',
)

test_executable = executable(
    'jots-unit-tests',
    gresource,
    test_sources,
    config_file,
    dependencies: dependencies,
    c_args: ['-w'],
    install: true
)

test_env = environment()
test_env.set('GSK_RENDERER', 'cairo')
test_env.set('GTK_A11Y', 'none')

test('canary-unit-tests', test_executable, env: test_env, is_parallel: true)