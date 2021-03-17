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

// Cannot subclass Gtk.ModelButton so put it in a Bin
public class Keyboard.Widgets.LayoutButton : Gtk.Bin {
    private Gtk.ModelButton button;
    public uint32 index { get; set construct; }
    public string language_code { get; set construct; }
    public string? layout_variant { get; set construct; }
    public string manager_type { get; set construct; }
    public string source { get; set construct; }

    public bool active {
        get {
            return button.active;
        }

        set {
            button.active = value;
        }
    }

    public LayoutButton (string caption,
                         string manager_type,
                         string source,
                         string code,
                         string? variant,
                         uint32 id,
                         string _action_name,
                         Variant _action_target) {

        Object (
            index: id,
            language_code: code,
            layout_variant: variant,
            manager_type: manager_type,
            source: source
        );

        button = new Gtk.ModelButton () {
            action_name = _action_name,
            action_target = _action_target,
            text = caption
        };

        expand = true;
        add (button);
        show_all ();
    }
}
