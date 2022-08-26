/*-
 * Copyright 2015-2019 elementary, Inc. (https://elementary.io)
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

public class Keyboard.Widgets.KeyboardIcon : Gtk.Label {
    construct {
        margin_top = 2;
        margin_bottom = 2;
        margin_start = 2;
        margin_end = 2;
        set_size_request (20, 20);
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/desktop/wingpanel/keyboard/KeyboardIcon.css");

        var style_context = get_style_context ();
        style_context.add_class ("keyboard-icon");
        style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
