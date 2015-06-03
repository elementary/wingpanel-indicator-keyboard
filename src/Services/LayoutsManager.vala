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

	public uint32 id;

	public int total;

	public Gtk.Button[] language;

	private GLib.Settings settings;

	public signal void updated ();

	public class LayoutManager () {
		settings = new GLib.Settings ("org.gnome.desktop.input-sources");

		this.set_orientation (Gtk.Orientation.VERTICAL);

		language = new Gtk.Button[10];

		settings.changed.connect ((key) => {
			if (key == "sources")
				this.update ();
			updated ();
		});
		update ();
	}

	//updates layout grid and returns current layout
	public void update () {
		clear ();
		var source_list = settings.get_value ("sources");

		total = 0;
		bool add = false;

		foreach ( var a in source_list) {
			foreach (var b in a) {
				stdout.printf (@"$(b.get_string ())\n");
				if (add) {
					language[total] = new LayoutButton (b.get_string (), total);
					this.add (language[total]);

					add = false;
					total++;
				} else
					add = true;
			}
		}
		this.show_all ();
	}

	public string get_current (bool shorten = false) {
		var current = settings.get_value ("current");

		if (shorten)
			return language[current.get_uint32 ()].label[0:2];
		else
			return language[current.get_uint32 ()].label;
	}

	public void clear () {
		foreach (var child in this.get_children ()){
			if (child is Gtk.Button)
			this.remove (child);
		}
	}
}
