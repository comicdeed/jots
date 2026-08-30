project(
    'jots',
    ['c', 'vala'],        # The floor is vala
    license: 'GPL-3.0-or-later',
    version: '1.3.0-beta.2',
    meson_version: '>= 0.59.0'
)

app_name = meson.project_name()
app_version = meson.project_version()
nicename = 'Jots'
publisher = 'comicdeed'

app_id = 'io.github.' + publisher + '.' + app_name
app_path = '/io/github/' + publisher + '/' + app_name

add_project_arguments('--define=LATTE', language: 'vala')

#================================
# Preparation

prefix = get_option('prefix')
datadir = get_option('datadir')

development = get_option('development')
if development
  app_id +=  '.devel'
    add_project_arguments('--define=DEVEL', language: 'vala')

endif

gnome = import('gnome')
i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (app_id), language:'c')


# Play nice with clang
# https://gitlab.gnome.org/GNOME/vala/-/issues/1413#note_1707480
if meson.get_compiler ('c').get_id () == 'clang'
    add_project_arguments('-Wno-incompatible-function-pointer-types', language: 'c')
endif


#================================
# Cool icon variants
icon_variant = get_option('icon_variant')

if icon_variant == 'halloween'
    add_project_arguments('--define=HALLOWEEN', language: 'vala')

else
    add_project_arguments('--define=DEFAULT', language: 'vala')

endif


#================================
# OS and Ports related

linux = get_option('profile') == 'linux'
windows = get_option('profile') == 'windows'

# Here is to autodetect and adjust
# Remember however that people may do cross compiling, so do not assume by default it is for linux
# So avoid else conditions adding linux stuff
build_machine_system = build_machine.system()

if build_machine_system == 'windows'
    windows = true

endif

# Here is to adjust the project accordingly to stuff
# Porting efforts: add your OS here

if windows
    add_project_arguments('--define=WINDOWS', language: 'vala')
    appstream = false
    libportal = false

else
    # Ideal case, Linux, with all the things
    appstream = true
    libportal = true

endif


#================================
# Add subfolders for Meson to look

app_numeric_version = app_version.split('-')[0] + '.0'

config_data = configuration_data(
    {
        'APP_NAME': app_name,
        'APP_ID': app_id,
        'APP_PATH': app_path,
        'APP_VERSION': app_version,
        'APP_NUMERIC_VERSION': app_numeric_version,
        'NICENAME': nicename,
        'PUBLISHER': publisher,
        'LOCALEDIR': prefix / get_option('localedir')
    }
)

subdir('po')
subdir('data')
subdir('src')

if windows
    subdir('windows')
endif

subdir('tests')


gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true
)
