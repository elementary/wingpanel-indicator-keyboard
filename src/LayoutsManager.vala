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

    private GLib.Settings settings;
    private Gtk.Grid main_grid;

    public LayoutManager () {
        populate_layouts ();
    }

    construct {
        main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        hscrollbar_policy = Gtk.PolicyType.NEVER;
        max_content_height = 500;
        propagate_natural_height = true;
        add (main_grid);

        settings = new GLib.Settings ("org.gnome.desktop.input-sources");
        settings.changed["sources"].connect (() => {
            clear ();
            populate_layouts ();
            updated ();
        });

        settings.changed["current"].connect_after (() => {
            updated ();
        });

        show_all ();
    }

    private void populate_layouts () {
        var source_list = settings.get_value ("sources");
        LayoutButton layout_button = null;
        var iter = source_list.iterator ();

        // Don't construct widgets if we're not going to show the indicator anyway
        if (iter.n_children () <= 1) {
            return;
        }

        int i = 0;
        string manager_type;
        string source;
        while (iter.next ("(ss)", out manager_type, out source)) {
            switch (manager_type) {
                case "xkb":
                    string? name;
                    string language;
                    string? variant = null;
                    if ("+" in source) {
                        var layouts = source.split ("+", 2);
                        language = layouts[0];
                        variant = layouts[1];
                    } else {
                        language = source;
                    }

                    name = get_name_for_xkb_layout (language, variant);
                    layout_button = new LayoutButton (name, language, variant, i, settings, layout_button);
                    main_grid.add (layout_button);
                    break;
                case "ibus":
                    // source contains the IBus engine name, how do we implement it ?
                    break;
            }

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
                if (button.radio_button.active) {
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
            current = button.code;
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
            current = button.code;
            if (button.variant != null) {
                current += "\t" + button.variant;
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

        settings.set_value ("current", next);
    }

    public void clear () {
        main_grid.get_children ().foreach ((child) => {
            child.destroy ();
        });
    }

    public bool has_multiple_layouts () {
        return main_grid.get_children ().length () > 1;
    }
}
