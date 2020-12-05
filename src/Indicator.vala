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
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private Gdk.Keymap keymap;
    private GLib.Settings settings;
    private Gtk.Grid indicator_grid;
    private Gtk.Grid main_grid;
    private Gtk.Revealer numlock_revealer;
    private Gtk.Revealer capslock_revealer;
    private Keyboard.Widgets.LayoutManager layouts;
    private Keyboard.Widgets.KeyboardIcon layouts_icon;
    private Gtk.Revealer layouts_revealer;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (
            code_name: Wingpanel.Indicator.KEYBOARD,
            server_type: server_type
        );
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_grid == null) {
            var numlock_icon = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            numlock_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
            };
            numlock_revealer.add (numlock_icon);

            var capslock_icon = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            capslock_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
            };
            capslock_revealer.add (capslock_icon);

            layouts_icon = new Keyboard.Widgets.KeyboardIcon ();

            layouts_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
            };
            layouts_revealer.add (layouts_icon);

            indicator_grid = new Gtk.Grid () {
                valign = Gtk.Align.CENTER
            };
            indicator_grid.add (numlock_revealer);
            indicator_grid.add (capslock_revealer);
            indicator_grid.add (layouts_revealer);

            settings = new GLib.Settings ("io.elementary.wingpanel.keyboard");
            keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());

            settings.changed.connect (() => {
                update_visibiity ();
            });

            keymap.state_changed.connect (() => {
                update_visibiity ();
            });

            indicator_grid.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    layouts.next ();
                    return Gdk.EVENT_STOP;
                }
                return Gdk.EVENT_PROPAGATE;
            });

            layouts = new Keyboard.Widgets.LayoutManager ();
            layouts.updated.connect (() => {
                update_visibiity ();
            });

            layouts.updated ();
            update_tooltip ();
        }

        return indicator_grid;
    }

    private void update_visibiity () {
        layouts_icon.label = layouts.get_current (true);

        layouts_revealer.reveal_child = layouts.has_multiple_layouts () || settings.get_boolean ("always-show-layout");
        numlock_revealer.reveal_child = keymap.get_num_lock_state () && settings.get_boolean ("numlock");
        capslock_revealer.reveal_child = keymap.get_caps_lock_state () && settings.get_boolean ("capslock");

        if (numlock_revealer.reveal_child && (layouts_revealer.reveal_child || capslock_revealer.reveal_child)) {
            numlock_revealer.margin_end = 6;
        } else {
            numlock_revealer.margin_end = 0;
        }

        if (capslock_revealer.reveal_child && layouts_revealer.reveal_child) {
            capslock_revealer.margin_end = 6;
        } else {
            capslock_revealer.margin_end = 0;
        }

        visible = layouts_revealer.reveal_child || numlock_revealer.reveal_child || capslock_revealer.reveal_child;
        update_tooltip ();
    }

    public override Gtk.Widget? get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            main_grid.set_orientation (Gtk.Orientation.VERTICAL);

            var separator = new Wingpanel.Widgets.Separator ();

            var map_button = new Gtk.ModelButton ();
            map_button.text = _("Show keyboard layout");
            map_button.clicked.connect (show_keyboard_map);

            main_grid.add (layouts);
            main_grid.add (separator);

            if (server_type != Wingpanel.IndicatorManager.ServerType.GREETER) {
                var settings_button = new Gtk.ModelButton ();
                settings_button.text = _("Keyboard Settings…");
                settings_button.clicked.connect (show_settings);

                main_grid.add (settings_button);
            }

            main_grid.add (map_button);
            main_grid.show_all ();
        }

        return main_grid;
    }

    public override void opened () {}

    public override void closed () {}

    private void show_settings () {
        close ();

        try {
            AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    private void show_keyboard_map () {
        close ();

        string command = "gkbd-keyboard-display \"--layout=" + layouts.get_current_with_variant () + "\"";

        try {
            AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE).launch (null, null);
        } catch (Error e) {
            warning ("Error launching keyboard layout display: %s", e.message);
        }
    }

    private void update_tooltip () {
        string message = "";

        if (keymap.get_num_lock_state () && settings.get_boolean ("numlock") &&
            keymap.get_caps_lock_state () && settings.get_boolean ("capslock") ) {
            message = "Caps Lock &amp; Num Lock are on";
        } else if (keymap.get_num_lock_state () && settings.get_boolean ("numlock")) {
            message = "Num Lock is on";
        } else if (keymap.get_caps_lock_state () && settings.get_boolean ("capslock")) {
            message = "Caps Lock is on";
        }

        indicator_grid.tooltip_markup = Granite.markup_accel_tooltip ({}, _(message));
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Keyboard Indicator");
    var indicator = new Keyboard.Indicator (server_type);
    return indicator;
}
