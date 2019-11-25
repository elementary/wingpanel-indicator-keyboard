i18n.merge_file(
    input: 'keyboard.appdata.xml.in',
    output: 'io.elementary.wingpanel.keyboard.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)

i18n.merge_file(
    input: 'keyboard.gschema.xml.in',
    output: 'io.elementary.wingpanel.keyboard.gschema.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

