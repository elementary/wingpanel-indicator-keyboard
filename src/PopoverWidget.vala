/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


public class Keyboard.Widgets.PopoverWidget : Gtk.Box {
    public const string XKB_RULES_FILE = "evdev.xml";
    public const string XKB_MANAGER_TYPE = "xkb";
    public const string IBUS_MANAGER_TYPE = "ibus";

    public string current_language_code { get; set; default = "";}
    public string current_layout_variant { get; set; default = "";}

    public signal void updated ();

    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private GLib.Settings settings;
#if IBUS_1_5_19
    private List<IBus.EngineDesc> engines;
#else
    private List<weak IBus.EngineDesc> engines;
#endif
    private Gtk.ListBox xkb_box;
    private Gtk.ListBox ibus_box;
    private Gtk.Revealer ibus_box_revealer;
    private Gtk.Revealer ibus_header_revealer;
    private Granite.SwitchModelButton ibus_header;

    private IBus.Bus bus;

    public PopoverWidget (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (server_type: server_type);
    }

    construct {
        orientation = VERTICAL;

        IBus.init ();
        bus = new IBus.Bus ();

        xkb_box = new Gtk.ListBox ();

        var xkb_header = new Granite.HeaderLabel (_("Keyboard Layout")) {
            mnemonic_widget = xkb_box
        };

        ibus_header = new Granite.SwitchModelButton (_("Input Method")) {
            active = true
        };
        ibus_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var ibus_separator = new Gtk.Separator (HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var ibus_header_box = new Gtk.Box (VERTICAL, 0);
        ibus_header_box.add (ibus_separator);
        ibus_header_box.add (ibus_header);

        ibus_header_revealer = new Gtk.Revealer () {
            child = ibus_header_box
        };

        ibus_box = new Gtk.ListBox ();
        ibus_box.get_accessible ().accessible_name = _("Input Method");

        ibus_box_revealer = new Gtk.Revealer () {
            child = ibus_box
        };

        var separator = new Gtk.Separator (HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var map_button = new Gtk.ModelButton () {
            text = _("Show Keyboard Layout")
        };
        map_button.clicked.connect (show_keyboard_map);

        add (xkb_header);
        add (xkb_box);
        add (ibus_header_revealer);
        add (ibus_box_revealer);
        add (separator);
        add (map_button);

        if (server_type != GREETER) {
            var settings_button = new Gtk.ModelButton () {
                text = _("Keyboard Settings…")
            };
            settings_button.clicked.connect (show_settings);

            add (settings_button);
        }

        bus.connected.connect (() => {
            populate_layouts ();
        });

        bus.disconnected.connect (() => {
            populate_layouts ();
        });

        settings = new GLib.Settings ("org.gnome.desktop.input-sources");

        settings.changed["current"].connect_after (() => {
            set_active_layout_from_settings (); // Gala will set the keymap if required
            updated ();
        });

        ibus_header.toggled.connect (() => {
            if (ibus_header.active) {
                ibus_box_revealer.reveal_child = true;
            } else {
                ibus_box_revealer.reveal_child = false;
                set_active_layout_to_xkb ();
            }
        });

        var action_change_current_layout = new SimpleAction.stateful (
            "change-layout",
            new VariantType ("u"),
            new Variant.boolean (true)
        );
        action_change_current_layout.activate.connect (action_change_layout);

        var actions = new SimpleActionGroup ();
        actions.add_action (action_change_current_layout);

        insert_action_group ("manager", actions);

        show_all ();

        var layout_manager = LayoutManager.get_default ();
        layout_manager.input_sources.items_changed.connect (populate_layouts);

        populate_layouts ();
    }

    private void show_settings () {
        try {
            AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void show_keyboard_map () {
        string command = "gkbd-keyboard-display \"--layout=" + get_current_with_variant () + "\"";

        try {
            AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE).launch (null, null);
        } catch (Error e) {
            warning ("Error launching keyboard layout display: %s", e.message);
        }
    }

    private void populate_layouts () {
        while (xkb_box.get_row_at_index (0) != null) {
            xkb_box.remove (xkb_box.get_row_at_index (0));
        }

        while (ibus_box.get_row_at_index (0) != null) {
            ibus_box.remove (ibus_box.get_row_at_index (0));
        }

        ibus_header_revealer.reveal_child = false;
        ibus_box_revealer.reveal_child = false;

        var source_list = settings.get_value ("sources");
        engines = null;
        if (bus.is_connected ()) {
            engines = bus.list_engines ();
            set_ibus_engine (XKB_MANAGER_TYPE, "");
        }

        LayoutButton layout_button = null;
        var iter = source_list.iterator ();
        uint32 i = 0;
        string manager_type;
        string source;
        while (iter.next ("(ss)", out manager_type, out source)) {
            string language = "us";
            string? layout_variant = null;
            string? button_label = null;

            switch (manager_type) {
                case XKB_MANAGER_TYPE:
                    if ("+" in source) {
                        var layouts = source.split ("+", 2);
                        language = layouts[0];
                        layout_variant = layouts[1];
                    } else {
                        language = source;
                    }

                    // Get translated layout name (or null)
                    button_label = get_name_for_xkb_layout (language, layout_variant);
                    break;
                case IBUS_MANAGER_TYPE:
                    if (engines == null) {
                        continue;
                    }

                    foreach (var engine in engines) {
                        if (engine != null && engine.name == source) {
                            if (source.contains ("xkb")) {
                                button_label = engine.get_longname ();
                            } else {
                                var lang_name = IBus.get_language_name (engine.get_language ());
                                button_label = "%s (%s)".printf (lang_name, engine.get_longname ());
                            }

                            language = engine.get_language ();
                            layout_variant = engine.get_layout_variant ();
                        }
                    }

                    break;
                default:
                    warning ("unrecognised input manager %s", manager_type);
                    continue;
            }

            layout_variant = layout_variant ?? "";

            // Provide a fallback label if required
            if (button_label == null) {
                //Better to use language code than nothing
                string variant = "";
                if (layout_variant != "") {
                    variant = " (%s)".printf (layout_variant);
                }

                button_label = language + variant;
            }

            var action_target = new Variant ("u", i);

            layout_button = new LayoutButton (
                button_label.replace ("_", "__"), //Underscores are swallowed if not doubled
                "manager.change-layout",
                action_target
            ) {
                index = i,
                language_code = language,
                layout_variant = layout_variant ?? "",
                manager_type = manager_type,
                source = source
            };

            /* XKB abd IBUS buttons added to different boxes to ensure they appear in separate sets and so they can
             * be shown and handled differently as required
             */
            switch (manager_type) {
                case XKB_MANAGER_TYPE:
                    xkb_box.add (layout_button);
                    break;
                case IBUS_MANAGER_TYPE:
                    ibus_box.add (layout_button);
                    break;
                default:
                    assert_not_reached ();
            }

            i++;
        }

        if (ibus_box.get_row_at_index (0) != null) {
            ibus_header_revealer.reveal_child = true;
            ibus_box_revealer.reveal_child = ibus_header.active;
        }

        set_active_layout_from_settings ();
        show_all ();
    }

    public string get_xml_rules_file_path () {
        unowned string? base_path = GLib.Environment.get_variable ("XKB_CONFIG_ROOT");
        if (base_path == null) {
            base_path = Constants.XKB_BASE;
        }

        return Path.build_filename (base_path, "rules", XKB_RULES_FILE);
    }

    private void action_change_layout (SimpleAction action, Variant? parameter) {
        uint32 current_source_index;
        parameter.@get ("u", out current_source_index);

        set_active_layout (current_source_index);

        if (settings.get_value ("current") != current_source_index) {
            settings.set_value ("current", current_source_index); // Causes Gala to set keymap only if not ibus type
        }
    }

    private void set_ibus_engine (string manager,
                                  string source) {
        switch (manager) {
            case XKB_MANAGER_TYPE:
                //This engine just echo keys so this results in the current xkb keyboard layout set by Gala being used
                bus.set_global_engine ("xkb:us::eng");
                break;
            case IBUS_MANAGER_TYPE:
                bus.set_global_engine (source);
                break;
            default:
                warning ("unrecognised input manager %s", manager);
                break;
        }
    }

    public string? get_name_for_xkb_layout (string language, string? variant) {
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

    public string get_current_with_variant () {
        if (current_layout_variant != "") {
            return current_language_code + "\t" + current_layout_variant;
        } else {
            return current_language_code;
        }
    }

    public string get_current_description () {
        string xkb_label = _("Default keyboard layout");  //Fallback
        string ibus_label = "";

        for (int i = 0; xkb_box.get_row_at_index (i) != null; i++) {
            var layout_button = (LayoutButton) xkb_box.get_row_at_index (i).get_child ();
            if (layout_button.active) {
                xkb_label = _("Keyboard Layout: %s").printf (layout_button.label);
            }
        }

        for (int i = 0; ibus_box.get_row_at_index (i) != null; i++) {
            var layout_button = (LayoutButton) ibus_box.get_row_at_index (i).get_child ();
            if (layout_button.active) {
                ibus_label = _("Input Method: %s").printf (layout_button.label);
            }
        }

        if (ibus_label != "") {
            return "%s\n%s".printf (ibus_label, xkb_label);
        } else {
            return xkb_label;
        }
    }

    public void next () {
        var current = settings.get_value ("current");
        var next = current.get_uint32 () + 1;
        if (next >= settings.get_value ("sources").n_children ()) {
            next = 0;
        }

        settings.set_value ("current", next); //Buttons will update via settings signal.
    }

    private void set_active_layout_from_settings () {
        set_active_layout (settings.get_value ("current").get_uint32 ());
    }

    private void set_active_layout_to_xkb () {
        for (int i = 0; xkb_box.get_row_at_index (i) != null; i++) {
            var layout_button = (LayoutButton) xkb_box.get_row_at_index (i).get_child ();
            if (layout_button.active) {
                settings.set_value ("current", layout_button.index);
                set_ibus_engine (XKB_MANAGER_TYPE, layout_button.source); //Make sure ibus input method not active.
            }
        }
    }

    private void set_active_layout (uint32 index) {
        set_layout_active_in_box (xkb_box, index, false); // Must be exactly one xkb layout active
        set_layout_active_in_box (ibus_box, index, true); // May be no ibus engine active

        updated ();
    }

    private void set_layout_active_in_box (Gtk.ListBox layout_box, uint index, bool clear) {
        bool found = false;
        LayoutButton? previously_active_button = null;

        /* Do not assume what order the buttons will be put in box */
        for (int i = 0; layout_box.get_row_at_index (i) != null; i++) {
            var layout_button = (LayoutButton) layout_box.get_row_at_index (i).get_child ();
            if (layout_button.index == index) {
                found = true;
                layout_button.active = true;
                current_language_code = layout_button.language_code;
                current_layout_variant = layout_button.layout_variant;

                if (bus.is_connected ()) {
                    set_ibus_engine (layout_button.manager_type, layout_button.source);
                }
            } else if (layout_button.active) {
                previously_active_button = (owned) layout_button;
            }
        }

        if (found) {
            if (previously_active_button != null) {
                previously_active_button.active = false;
            }
        } else if (clear) {
            for (int i = 0; layout_box.get_row_at_index (i) != null; i++) {
                var layout_button = (LayoutButton) layout_box.get_row_at_index (i).get_child ();
                layout_button.active = false;
            }
        }
    }

    public bool has_multiple_layouts () {
        return settings.get_value ("sources").n_children () > 1;
    }
}
