/*
 * Copyright 2017-2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

/**
 * Respresents a keyboard-InputSource according to "org.gnome.desktop.input-sources sources".
 * This means that the enum parameter @layout_type equals the first string in the
 * tupel of strings, and the @name parameter equals the second string.
 */
public class Keyboard.InputSource : Object {
    /**
     * Type of a keyboard-InputSource as described in the description of
     * "org.gnome.desktop.input-sources sources".
     */
    public enum LayoutType {
        IBUS,
        XKB 
    }

    public LayoutType layout_type { get; construct; }

    // Name of input source as stored in settings e.g. "gb" (xkb) or "xkb:gb:extd:eng" (ibus) or "mozc-jp" (ibus)
    // These names are used both in org/gnome/desktop/input-sources and desktop/ibus/general/preload-engines
    public string name { get; construct; }

    private InputSource (LayoutType layout_type, string name) {
        Object (
            layout_type: layout_type,
            name: name
        );
    }


    public static InputSource? new_from_variant (Variant? variant) {
        if (!variant.is_of_type (new VariantType ("(ss)"))) {
            critical ("Ignoring attempt to create InputSource from invalid VariantType");
            return null;
        }

        unowned string type;
        unowned string name;
        variant.get ("(&s&s)", out type, out name);

        if (name == "") {
            critical ("Attempt to create invalid InputSource name %s", name);
            return null;
        }

        if (type == "xkb") {
            return new InputSource (LayoutType.XKB, name);
        } else if (type == "ibus") {
            return new InputSource (LayoutType.IBUS, name);
        }

        return null;
    }

    public bool equal (InputSource other) {
        return layout_type == other.layout_type && name == other.name;
    }

    /**
     * GSettings saves values in the form of GLib.Variant and this
     * function creates a Variant representing this object.
     */
    public GLib.Variant to_variant () requires (name != "") {
        string type_name = "";
        switch (layout_type) {
            case LayoutType.IBUS:
                type_name = "ibus";
                break;
            case LayoutType.XKB:
                type_name = "xkb";
                break;
            default:
                assert_not_reached ();
        }
        GLib.Variant first = new GLib.Variant.string (type_name);
        GLib.Variant second = new GLib.Variant.string (name);
        GLib.Variant result = new GLib.Variant.tuple ({first, second});

        return result;
    }
}
