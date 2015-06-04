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

public class Keyboard.Indicator : Wingpanel.Indicator {

	private const string SETTINGS_EXEC = "/usr/bin/switchboard keyboard";

	public Gtk.Grid main_grid;

	public Keyboard.Widgets.KeyboardIcon display_icon;

	public Keyboard.Widgets.LayoutManager layouts;
	
	public Wingpanel.Widgets.IndicatorButton settings_button;
	private Wingpanel.Widgets.IndicatorSeparator separator;
	public Indicator () {
		Object (code_name: Wingpanel.Indicator.KEYBOARD,
				display_name: _("Keyboard"),
				description:_("The keyboard layouts indicator"));
	}

	public override Gtk.Widget get_display_widget () {
		if (display_icon == null) {
			display_icon = new Keyboard.Widgets.KeyboardIcon ();
			display_icon.set_lang ("Us");
			
			display_icon.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    layouts.next ();
                    return Gdk.EVENT_STOP;
                }
                return Gdk.EVENT_PROPAGATE;
            });			
		}
		return display_icon;
	}

	public override Gtk.Widget? get_widget () {
		if (main_grid == null) {
			main_grid = new Gtk.Grid ();
			main_grid.set_orientation (Gtk.Orientation.VERTICAL);

			layouts = new Keyboard.Widgets.LayoutManager ();

			separator = new Wingpanel.Widgets.IndicatorSeparator ();

			settings_button = new Wingpanel.Widgets.IndicatorButton (_("Keyboard Settings") + "…");
			connections ();

			layouts.updated ();

			main_grid.add (layouts);
			main_grid.add (separator);
			main_grid.add (settings_button);
			main_grid.show_all ();
		}

		return main_grid;
	}

	public override void opened () {}

	public override void closed () {}

	private void connections () {
		settings_button.clicked.connect (show_settings);

		layouts.updated.connect (() => {
			close ();
			display_icon.set_lang (layouts.get_current (true));

			if (layouts.total < 2)
				this.visible = false;
			else
				this.visible = true;
		});
	}

	private void show_settings () {
		close ();
		var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
		cmd.run ();
	}
}

public Wingpanel.Indicator get_indicator (Module module) {
	debug ("Activating Keyboard Indicator");
	var indicator = new Keyboard.Indicator ();
	return indicator;
}
