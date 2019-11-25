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

public class Keyboard.KeyboardStatusIndicator : Wingpanel.Indicator {
    public bool capslock_status { get; set; }
    public bool numlock_status { get; set; }
    private Gtk.Box display_widget;
    private Gtk.Box popover_widget;
    private GLib.Settings settings;
    private Gtk.Label capslock;
    private Gtk.Label numlock;
    private Gdk.Keymap keymap;

    public KeyboardStatusIndicator () {
        Object (
            code_name : "keyboard-status-indicator",
            display_name : _("Keyboard Status Indicator"),
            description: _("Shows the Capslock or Numlock status in the wingpanel")
        );
    }

    construct {
        visible = false;
        settings = new GLib.Settings ("io.elementary.wingpanel.keyboard-status");
        keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/desktop/wingpanel/keyboard/KeyboardIcon.css");

        numlock = new Gtk.Label ("1");
        numlock.margin = 2;
        numlock.set_size_request (20, 20);
        numlock.halign = Gtk.Align.CENTER;
        numlock.valign = Gtk.Align.CENTER;
        numlock.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        numlock.get_style_context ().add_class ("keyboard-disabled");

        capslock = new Gtk.Label ("A");
        capslock.margin = 2;
        capslock.set_size_request (20, 20);
        capslock.halign = Gtk.Align.CENTER;
        capslock.valign = Gtk.Align.CENTER;
        capslock.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        capslock.get_style_context ().add_class ("keyboard-disabled");

        activate_indicator ();

        settings.change_event.connect (() => {
            activate_indicator ();
        });

        keymap.state_changed.connect (update_keys);

        notify["numlock-status"].connect (() => {
            if (numlock_status) {
                numlock.get_style_context ().remove_class ("keyboard-disabled");
                numlock.get_style_context ().add_class ("keyboard-icon");
            } else {
                numlock.get_style_context ().remove_class ("keyboard-icon");
                numlock.get_style_context ().add_class ("keyboard-disabled");
            }
        });

        notify["capslock-status"].connect (() => {
            if (capslock_status) {
                capslock.get_style_context ().remove_class ("keyboard-disabled");
                capslock.get_style_context ().add_class ("keyboard-icon");
            } else {
                capslock.get_style_context ().remove_class ("keyboard-icon");
                capslock.get_style_context ().add_class ("keyboard-disabled");
            }
        });
    }

    public override Gtk.Widget get_display_widget () {
        if (display_widget == null) {
            display_widget = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            display_widget.valign = Gtk.Align.CENTER;
            display_widget.pack_start (numlock, false, false);
            display_widget.pack_end (capslock, false, false);
        }

        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Keyboard Settings…");
            settings_button.clicked.connect (show_settings);

            popover_widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            popover_widget.expand = true;
            popover_widget.pack_end (settings_button, false, false);
        }

        return popover_widget;
    }

    public override void opened () {}

    public override void closed () {}

    private void activate_indicator () {
        if (settings.get_boolean ("numlock") || settings.get_boolean ("capslock")) {
            visible = true;
            update_keys ();
            numlock.visible = settings.get_boolean ("numlock") ? true : false;
            capslock.visible = settings.get_boolean ("capslock") ? true : false;
        } else {
            visible = false;
        }
    }

    private void update_keys () {
        set_property ("capslock-status", keymap.get_caps_lock_state ());
        set_property ("numlock-status", keymap.get_num_lock_state ());
    }

    private void show_settings () {
        close ();
        try {
            AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug (_("Activating Keyboard Status Indicator"));

    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    return new Keyboard.KeyboardStatusIndicator ();
}
