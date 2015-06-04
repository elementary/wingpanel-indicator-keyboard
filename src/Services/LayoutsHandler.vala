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

public class Keyboard.Services.LayoutHandler : GLib.Object {
	InternalLayout[]  layouts;
	private string[] names;
	private string[] codes;
	
	//TODO currently using switchboard's layout file
	private const string LAYOUTFILE = "/usr/lib/x86_64-linux-gnu/switchboard/hardware/pantheon-keyboard/layouts.txt";

	public LayoutHandler ()	{
		foreach (var l in parse_layouts ())	{
			var parts = l.split(":", 2);

			names += parts[0];
			codes += parts[1];

			layouts += new InternalLayout (parse_variants (l));
		}
	}

	public string[] get_layouts () {
		return names;
	}

	public string[] get_variants (uint index) {
		return layouts[index].names;
	}

	public string get_code (uint l, uint v)	{
		if (v != 0)
			return codes[l] + "+" + layouts[l].codes[v];
		return codes[l];
	}

	public string get_name (uint l, uint v)	{
		if (v != 0)
			return layouts[l].names[v];
		return names[l];
	}

	public bool from_code (string code, out uint l, out uint v)	{
		var parts = code.split("+", 2);

		l = v = 0;

		if (parts[0] == null) return false;

		while (codes[l] != parts[0])
			if (l++ > codes.length)
				return false;

		if (parts[1] == null) return true;

		while (layouts[l].codes[v] != parts[1])
			if (v++ > layouts[l].codes.length)
				return false;

		return true;
	}

	// private class that contains the variants of one language
	private class InternalLayout : GLib.Object {
		public string[] names;
		public string[] codes;

		public InternalLayout (string[] variants )	{
			names += _("Default");
			codes += "";

			foreach (var v in variants)	{
				var parts = v.split(":", 2);

				names += parts[0];
				codes += parts[1];
			}
		}
	}

	// private functions to parse the files
	private string[]? parse_layouts () {
		string[] return_val = null;
			//TODO SET FILE PATH
			var file = File.new_for_path (LAYOUTFILE);
			if (!file.query_exists ()) {
			warning ("File '%s' doesn't exist.\n", file.get_path ());
			return return_val;
		}
			try {
			var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null)
				if( "#" in line )
					return_val += line.replace ("#", "");
		} catch (Error e) {
			error ("%s", e.message);
		}
			return return_val;
	}

	private string[]? parse_variants (string language) {
		string[] return_val = null;

		var file = File.new_for_path (LAYOUTFILE);

		if (!file.query_exists ()) {
			warning ("File '%s' doesn't exist.\n", file.get_path ());
			return null;
		}

		try {
			var dis = new DataInputStream (file.read ());

			string line;

			while ((line = dis.read_line (null)) != null) {
				if (line == "#" + language) {
					while ((line = dis.read_line (null)) != null) {
						if( "#" in line ) break;
						return_val += line;
					}
					break;
				}
			}
		} catch (Error e) {
			error ("%s", e.message);
		}

		return return_val;
	}
}
