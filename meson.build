project(
    'keyboard',
    'vala', 'c',
    version: '2.2.0'
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

wingpanel_dep = dependency('wingpanel-2.0')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('libxml-2.0'),
    wingpanel_dep
]

shared_module(
    meson.project_name(),
    gresource,
    'src/Indicator.vala',
    'src/KeyboardIcon.vala',
    'src/LayoutButton.vala',
    'src/LayoutsManager.vala',
    dependencies: dependencies,
    install: true,
    install_dir : wingpanel_indicatorsdir
)

shared_module(
    meson.project_name() + '-status',
    'src/KeyboardStatusIndicator.vala',
    dependencies: dependencies,
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('po')
subdir('data')

meson.add_install_script('meson/post_install.py')
