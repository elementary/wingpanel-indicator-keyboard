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

public class Keyboard.Widgets.KeyboardIcon : Gtk.Image {

	private string icon_svg_data = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><svg version=\"1.1\" width=\"24\" height=\"24\"><defs><mask id=\"m\"><rect x=\"0\" y=\"0\" width=\"24\" height=\"24\" style=\"fill:white\"/><text x=\"%s\" y=\"15.5\" style=\"font-family:Open Sans;font-weight:500;font-size:10;fill:black\">%s</text></mask></defs><rect x=\"4\" y=\"4\" width=\"16\" height=\"16\" rx=\"2\" mask=\"url(#m)\" style=\"fill:#fff\"/></svg>";

	private Cairo.Context context;

	public KeyboardIcon () {
		Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
		context = new Cairo.Context (surface);
		context.select_font_face ("Open Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
	}

	// calculate x: middle line (24/2) - text_extent.width / 2
	public void set_lang (string code) {
		try {
			context.set_font_size (9);
			Cairo.TextExtents extents;
			context.text_extents (code, out extents);

			var replace_svg = icon_svg_data.printf ((12 - extents.width / 2).to_string (), code);
			var input = new GLib.MemoryInputStream.from_data (replace_svg.data, GLib.g_free);

			this.pixbuf = new Gdk.Pixbuf.from_stream (input);
		} catch (Error e) {
			warning ("unable to set pixbuf: %s", e.message);
		}
	}
}
