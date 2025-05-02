/*
 * Copyright 2017-2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * Respresents a keyboard-InputSource according to "org.gnome.desktop.input-sources sources".
 * This means that the enum parameter @layout_type equals the first string in the
 * tupel of strings, and the @name parameter equals the second string.
 */
public class Keyboard.InputSource : Object {
    public const string XKB_RULES_FILE = "evdev.xml";

    /**
     * Type of a keyboard-InputSource as described in the description of
     * "org.gnome.desktop.input-sources sources".
     */
    public enum LayoutType {
        IBUS,
        XKB;

        public string to_string () {
            switch (this) {
                case IBUS:
                    return "ibus";
                case XKB:
                    return "xkb";
            }

            return "";
        }
    }

    public LayoutType layout_type { get; construct; }

    /**
     * Name of input source as stored in settings e.g. "gb" (xkb) or "xkb:gb:extd:eng" (ibus) or "mozc-jp" (ibus)
     * These names are used both in org/gnome/desktop/input-sources and desktop/ibus/general/preload-engines
     */
    public string name { get; construct; }

    /**
     * A human-readable label for #this
     */
    public string label { get; private set; }

    /**
     * A human-readable language code like "en" or "jp" for #this
     */
    public string lang_code { get; private set; }

    /**
     * Layout variant to be used with gkbd-keyboard-display
     */
    public string layout_variant { get; private set; default = ""; }

    private static IBus.Bus bus;
#if IBUS_1_5_19
    private List<IBus.EngineDesc> engines;
#else
    private List<weak IBus.EngineDesc> engines;
#endif

    private InputSource (LayoutType layout_type, string name) {
        Object (
            layout_type: layout_type,
            name: name
        );
    }

    class construct {
        IBus.init ();
        bus = new IBus.Bus ();
    }

    construct {
        if (bus.is_connected ()) {
            engines = bus.list_engines ();
        }

        switch (layout_type) {
            case XKB:
                if ("+" in name) {
                    var layouts = name.split ("+", 2);
                    lang_code = layouts[0];
                    layout_variant = layouts[1];
                } else {
                    lang_code = name;
                }

                // Get translated layout name (or null)
                label = InputSource.get_name_for_xkb_layout (lang_code, layout_variant);
                break;
            case IBUS:
                foreach (unowned var engine in engines) {
                    if (engine != null && engine.name == name) {
                        if (name.contains ("xkb")) {
                            label = engine.get_longname ();
                        } else {
                            var lang_name = IBus.get_language_name (engine.get_language ());
                            label = "%s (%s)".printf (lang_name, engine.get_longname ());
                        }

                        lang_code = engine.get_language ();
                        layout_variant = engine.get_layout_variant ();
                        break;
                    }
                }

                break;
        }

        // Provide a fallback label if required
        if (label == null) {
            //Better to use language code than nothing
            string variant = "";
            if (layout_variant != "") {
                variant = " (%s)".printf (layout_variant);
            }

            label = lang_code + variant;
        }
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

    public static string? get_name_for_xkb_layout (string language, string? variant) {
        debug ("get_name_for_xkb_layout (%s, %s)", language, variant);
        Xml.Doc* doc = Xml.Parser.parse_file (get_xml_rules_file_path ());
        if (doc == null) {
            critical ("'%s' not found or permissions incorrect\n", XKB_RULES_FILE);
            return null;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        string xpath = "";

        if (variant == null) {
            xpath = @"/xkbConfigRegistry/layoutList/layout/configItem/name[text()='$language']/../description";
        } else {
            xpath = @"/xkbConfigRegistry/layoutList/layout/configItem/name[text()='$language']/../../variantList/variant/configItem/name[text()='$variant']/../description"; //vala-lint=line-length
        }

        Xml.XPath.Object* res = cntx.eval_expression (xpath);

        if (res == null) {
            delete doc;
            critical ("Unable to parse '%s'", XKB_RULES_FILE);
            return null;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            warning ("No name for %s: %s found in '%s'", language, variant, XKB_RULES_FILE);
            return null;
        }

        string? name = null;
        Xml.Node* node = res->nodesetval->item (0);
        if (node != null) {
            name = dgettext ("xkeyboard-config", node->get_content ());
        }

        delete res;
        delete doc;
        return name;
    }

    private static string get_xml_rules_file_path () {
        unowned string? base_path = GLib.Environment.get_variable ("XKB_CONFIG_ROOT");
        if (base_path == null) {
            base_path = Constants.XKB_BASE;
        }

        return Path.build_filename (base_path, "rules", XKB_RULES_FILE);
    }
}
