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


public class Keyboard.Widgets.LayoutManager : Gtk.Grid {

	// TODO Get icons from theme
	private const string ON = "/usr/share/themes/elementary/gtk-3.0/assets/radio-active.svg";
	private const string OFF = "/usr/share/themes/elementary/gtk-3.0/assets/radio.svg";

	public uint32 id;

	public int total;

	public Keyboard.Widgets.LayoutButton[] language;

	private GLib.Settings settings;

	private Keyboard.Services.LayoutHandler layout_handler;

	public signal void updated ();

	public class LayoutManager () {
		layout_handler = new Keyboard.Services.LayoutHandler ();

		settings = new GLib.Settings ("org.gnome.desktop.input-sources");

		this.set_orientation (Gtk.Orientation.VERTICAL);

		language = new Keyboard.Widgets.LayoutButton[15];

		settings.changed.connect (() => {
			clear ();
			update ();
			updated ();
		});
		update ();
	}

	//updates layout grid and returns current layout
	public void update () {
		clear ();
		var source_list = settings.get_value ("sources");
		var current = settings.get_value ("current");

		total = 0;
		bool add = false;

		foreach ( var a in source_list) {
			foreach (var b in a) {
				if (add && total < 15) {
					uint l; uint o;
					layout_handler.from_code (@"$(b.get_string ())", out l, out o);
					string language_name = layout_handler.get_name (l,o);

					if (current.get_uint32 () == total)
						language[total] = new LayoutButton (language_name, b.get_string (), total, ON);
					else
						language[total] = new LayoutButton (language_name, b.get_string (), total, OFF);
					this.add (language[total]);

					language[total].clicked.connect (() => {
						updated ();
					});

					add = false;
					total++;
				} else
					add = true;
			}
		}
		this.show_all ();
	}

	public void next () {
		var current = settings.get_value ("current");
		var act = current.get_uint32 () + 1;
		if (act >= total)
			act = 0;
		settings.set_value ("current", act);
	}

	public string get_current (bool shorten = false) {
		var current = settings.get_value ("current");

		if (shorten)
			return language[current.get_uint32 ()].code[0:2];
		else
			return language[current.get_uint32 ()].code;
	}

	public void clear () {
		foreach (var child in this.get_children ()){
			if (child is Gtk.Button)
			this.remove (child);
		}
	}
}
