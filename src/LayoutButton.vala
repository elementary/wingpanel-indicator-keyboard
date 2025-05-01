/*
 * Copyright 2015-2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

// Cannot subclass Gtk.ModelButton so put it in a Bin
public class Keyboard.Widgets.LayoutButton : Gtk.Bin {
    public string label { get; construct; }
    public string action_name { get; construct; }
    public Variant action_target { get; construct;}

    public bool active { get; set; }
    public uint32 index { get; set; }
    public string language_code { get; set; }
    public string? layout_variant { get; set; }
    public string manager_type { get; set; }
    public string source { get; set; }

    public LayoutButton (string _label, string _action_name, Variant _action_target) {
        Object (
            label: _label,
            action_name: _action_name,
            action_target: _action_target
        );
    }

    construct {
        var button = new Gtk.ModelButton () {
            text = label,
            action_name = action_name,
            action_target = action_target
        };

        child = button;
        show_all ();

        bind_property ("active", button, "active", BIDIRECTIONAL);
    }
}
