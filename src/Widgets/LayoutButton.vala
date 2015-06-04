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

public class Keyboard.Widgets.LayoutButton : Wingpanel.Widgets.IndicatorButton {
	public uint32 id;

	public string caption;
	public string code;

	private GLib.Settings settings;

	public LayoutButton (string caption, string code, uint32 id, string dir) {
		base.with_image (caption, new Gdk.Pixbuf.from_file (dir));
		
		this.caption = caption;
		this.code = code;
		this.id = id;

		this.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
		settings = new GLib.Settings ("org.gnome.desktop.input-sources");

		this.clicked.connect (() => {
			settings.set_value ("current", id);
		});
	}
}
