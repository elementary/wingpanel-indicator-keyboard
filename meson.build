project(
    'keyboard',
    'vala', 'c',
    version: '2.2.1'
)

i18n = import('i18n')
gnome = import('gnome')
gettext_name = meson.project_name() + '-indicator'

prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')

gresource = gnome.compile_resources(
    'gresource',
    join_paths('data', 'keyboard.gresource.xml'),
    source_dir: 'data'
)

xkbconf = dependency('xkeyboard-config')
xkb_base = xkbconf.get_pkgconfig_variable('xkb_base')

conf_data = configuration_data()
conf_data.set('XKB_BASE', xkb_base)
config_file = configure_file (
    input: 'src/Config.vala.in',
    output: 'Config.vala',
    configuration: conf_data
)

wingpanel_dep = dependency('wingpanel-2.0')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])


ibus_dep = dependency('ibus-1.0')
if(ibus_dep.version().version_compare('>=1.5.19'))
    add_project_arguments(['--define', 'IBUS_1_5_19'], language: 'vala')
endif

shared_module(
    meson.project_name(),
    gresource,
    'src/Indicator.vala',
    'src/KeyboardIcon.vala',
    'src/LayoutButton.vala',
    'src/LayoutsManager.vala',
    config_file,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libxml-2.0'),
        wingpanel_dep,
        ibus_dep,
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)

subdir('po')
subdir('data')

meson.add_install_script('meson/post_install.py')
