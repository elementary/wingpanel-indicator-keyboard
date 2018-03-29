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

public class Keyboard.Widgets.LayoutButton : Wingpanel.Widgets.Container {
    public uint32 id;
    public string code;
    public string? variant;
    public Gtk.RadioButton radio_button { private set; public get; }

    public LayoutButton (string caption, string code, string? variant, uint32 id, GLib.Settings settings, LayoutButton? layout_button) {
        radio_button = new Gtk.RadioButton.with_label_from_widget ((layout_button != null) ? layout_button.radio_button : null, caption);
        var current = settings.get_value ("current");
        radio_button.active = (current.get_uint32 () == id);
        radio_button.margin_start = 6;
        get_content_widget ().add (radio_button);

        this.id = id;
        this.code = code;
        this.variant = variant;

        this.clicked.connect (() => {
            settings.set_value ("current", id);
        });

        settings.changed["current"].connect (() => {
            current = settings.get_value ("current");
            if (current.get_uint32 () == id) {
                radio_button.active = true;
            }
        });
    }
}
