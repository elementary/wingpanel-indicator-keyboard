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


public class Keyboard.Widgets.LayoutManager : Gtk.ScrolledWindow {
    public const string XKB_RULES_FILE = "evdev.xml";

    public signal void updated ();
    public string current_language_code { get; set; }
    private GLib.Settings settings;
#if IBUS_1_5_19
    private List<IBus.EngineDesc> engines;
#else
    private List<weak IBus.EngineDesc> engines;
#endif
    private Gtk.Grid main_grid;

    private IBus.Bus bus;
    private SimpleActionGroup actions;

    public LayoutManager () {

    }

    construct {
        IBus.init ();
        bus = new IBus.Bus ();
        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        hscrollbar_policy = Gtk.PolicyType.NEVER;
        max_content_height = 500;
        propagate_natural_height = true;
        add (main_grid);

        settings = new GLib.Settings ("org.gnome.desktop.input-sources");
        settings.changed["sources"].connect (() => {
            clear ();
            populate_layouts ();
            set_active_button_from_settings ();
            updated ();
        });

        settings.changed["current"].connect_after (() => {
            set_active_button_from_settings ();
            updated ();
        });

        actions = new SimpleActionGroup ();
        var action_change_current_layout = new SimpleAction (
            "change-layout",
            new VariantType ("(sssu)")
        );

        action_change_current_layout.activate.connect (action_change_layout);
        actions.add_action (action_change_current_layout);
        insert_action_group ("manager", actions);

        show_all ();

        populate_layouts ();
        set_active_button_from_settings (); // Sets current_language_code
    }

    private void populate_layouts () {
        var source_list = settings.get_value ("sources");
        engines = bus.list_engines ();
        LayoutButton layout_button = null;
        var iter = source_list.iterator ();
        uint32 i = 0;
        string manager_type;
        string source;
        while (iter.next ("(ss)", out manager_type, out source)) {
            string name = "English";
            string language = "us";
            string? layout_variant = null;
            if (manager_type == "xkb") {
                if ("+" in source) {
                    var layouts = source.split ("+", 2);
                    language = layouts[0];
                    layout_variant = layouts[1];
                } else {
                    language = source;
                }

                name = get_name_for_xkb_layout (language, layout_variant);
            } else if (manager_type == "ibus" && engines != null) {
                foreach (var engine in engines) {
                    if (engine != null && engine.name == source) {
                        if (source.contains ("xkb")) {
                            name = engine.get_longname ();
                        } else {
                            var lang_name = IBus.get_language_name (engine.get_language ());
                            name = "%s (%s)".printf (lang_name, engine.get_longname ());
                        }

                        language = engine.get_language ();
                        layout_variant = engine.get_layout_variant ();
                    }
                }
            }

            var action_target = new Variant (
                "(sssu)",
                manager_type,
                language,
                layout_variant != null ? layout_variant : "",
                i
            );

            layout_button = new LayoutButton (
                name,
                manager_type,
                language,
                layout_variant,
                i,
                "manager.change-layout",
                action_target
            );

            main_grid.add (layout_button);

            i++;
        }

        main_grid.show_all ();
    }

    public string get_xml_rules_file_path () {
        unowned string? base_path = GLib.Environment.get_variable ("XKB_CONFIG_ROOT");
        if (base_path == null) {
            base_path = Constants.XKB_BASE;
        }

        return Path.build_filename (base_path, "rules", XKB_RULES_FILE);
    }

    private void action_change_layout (SimpleAction action, Variant? parameter) {
        string manager, language, variant;
        uint32 index;
        parameter.@get ("(sssu)", out manager, out language, out variant, out index);
        switch (manager) {
            case "xkb":
                settings.set_value ("current", index);
                break;
            case "ibus":
                settings.set_value ("current", index);
                break;
            default:
                warning ("unrecognised input manager %s", manager);
                break;
        }

        current_language_code = language;
        updated ();
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
            xpath = @"/xkbConfigRegistry/layoutList/layout/configItem/name[text()='$language']/../../variantList/variant/configItem/name[text()='$variant']/../description";
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

    private LayoutButton? get_current_layout_button () {
        LayoutButton? layout_button = null;

        main_grid.get_children ().foreach ((child) => {
            if (child is LayoutButton) {
                var button = (LayoutButton) child;
                if (button.active) {
                    layout_button = button;
                }
            }
        });

        return layout_button;
    }

    public string get_current (bool shorten = false) {
        string current = "us";
        var button = get_current_layout_button ();
        if (button != null) {
            current = button.language_code;
        }

        if (shorten) {
            return current[0:2];
        } else {
            return current;
        }
    }

    public string get_current_with_variant () {
        string current = "us";
        var button = get_current_layout_button ();
        if (button != null) {
            current = button.language_code;
            if (button.layout_variant != null) {
                current += "\t" + button.layout_variant;
            }
        }

        return current;
    }

    public void next () {
        var current = settings.get_value ("current");
        var next = current.get_uint32 () + 1;
        if (next >= main_grid.get_children ().length ()) {
            next = 0;
        }

        settings.set_value ("current", next); //Buttons will update via settings signal.
    }

    private void set_active_button_from_settings () {
        var current = settings.get_value ("current").get_uint32 ();
        var children = main_grid.get_children ();
        children.@foreach ((widget) => {
            var layout_button = (LayoutButton)widget;
            if (layout_button.index == current) {
                current_language_code = layout_button.language_code;
                layout_button.active = true; // This does not trigger the action
            } else {
                layout_button.active = false;
            }
        });
    }


    public void clear () {
        main_grid.get_children ().foreach ((child) => {
            child.destroy ();
        });
    }

    public bool has_layouts () {
        return main_grid.get_children ().length () >= 1;
    }
}
