/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class Keyboard.LayoutManager : Object {
    public string current_lang_code { get; private set; }
    public GLib.ListStore input_sources { get; private set; }

    private static GLib.Once<LayoutManager> layout_manager;
    public static LayoutManager get_default () {
        return layout_manager.once (() => {
            return new LayoutManager ();
        });
    }

    private GLib.Settings settings;

    private LayoutManager () {}

    construct {
        input_sources = new GLib.ListStore (typeof (InputSource));

        settings = new Settings ("org.gnome.desktop.input-sources");
        // FIXME: current key is deprecated https://github.com/elementary/gala/issues/2367
        settings.changed["current"].connect (update_current);
        settings.changed["sources"].connect (update_sources);
    }

    private void update_current () {
        var current_input_source = (InputSource) input_sources.get_item (settings.get_uint ("current"));
        current_lang_code = current_input_source.get_lang_code ();
    }

    private void update_sources () {
        input_sources.remove_all ();

        var sources = settings.get_value ("sources");
        for (size_t i = 0; i < sources.n_children (); i++) {
            var input_source = InputSource.new_from_variant (sources.get_child_value (i));

            uint pos = -1;
            if (!input_sources.find (input_source, out pos)) {
                input_sources.append (input_source);
            }
        }

        update_current ();
    }
}
