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
    private Gdk.Keymap keymap;
    private GLib.Settings settings;
    private Gtk.Grid display_widget;
    private Gtk.Grid main_grid;
    private Gtk.Image numlock;
    private Gtk.Image capslock;
    private Gtk.Revealer numlock_revealer;
    private Gtk.Revealer capslock_revealer;
    private Keyboard.Widgets.KeyboardIcon keyboard_layout_icon;
    private Keyboard.Widgets.LayoutManager layouts;

    public Indicator () {
        Object (code_name: Wingpanel.Indicator.KEYBOARD,
                display_name: _("Keyboard"),
                description:_("The keyboard layouts indicator"));
    }

    construct {
        this.visible = false;
        settings = new GLib.Settings ("io.elementary.wingpanel.keyboard");
        keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
        layouts = new Keyboard.Widgets.LayoutManager ();

        keyboard_layout_icon = new Keyboard.Widgets.KeyboardIcon ();
        keyboard_layout_icon.margin_start = 6;
        keyboard_layout_icon.no_show_all = true;

        numlock = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        numlock.use_fallback = true;
        numlock.margin = 2;
        numlock.halign = Gtk.Align.CENTER;
        numlock.valign = Gtk.Align.CENTER;
        numlock.no_show_all = true;
        numlock_revealer = new Gtk.Revealer ();
        numlock_revealer.add (numlock);

        capslock = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        capslock.use_fallback = true;
        capslock.margin = 2;
        capslock.halign = Gtk.Align.CENTER;
        capslock.valign = Gtk.Align.CENTER;
        capslock.no_show_all = true;
        capslock_revealer = new Gtk.Revealer ();
        capslock_revealer.add (capslock);

        layouts.updated.connect (() => {
            keyboard_layout_icon.label = layouts.get_current (true);

            if (keyboard_layout_icon.visible != layouts.has_layouts ()) {
                keyboard_layout_icon.visible = layouts.has_layouts ();
                update_indicator ();
            }
        });

        settings.change_event.connect (() => {
            update_indicator ();
        });

        keymap.state_changed.connect (() => {
            if (numlock.visible) {
                numlock_revealer.reveal_child = keymap.get_num_lock_state ();
            }

            if (capslock.visible) {
                capslock_revealer.reveal_child = keymap.get_caps_lock_state ();
            }
        });
    }

    public override Gtk.Widget get_display_widget () {
        if (display_widget == null) {
            display_widget = new Gtk.Grid ();
            display_widget.set_orientation (Gtk.Orientation.HORIZONTAL);
            display_widget.valign = Gtk.Align.CENTER;
            display_widget.add (numlock_revealer);
            display_widget.add (capslock_revealer);
            display_widget.add (keyboard_layout_icon);
            display_widget.show_all ();

            //applying only to the KeyboardIcon seems to result in nothing
            display_widget.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    layouts.next ();
                    return Gdk.EVENT_STOP;
                }

                return Gdk.EVENT_PROPAGATE;
            });

            update_indicator ();
            layouts.updated ();
            keymap.state_changed ();
        }

        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            main_grid.set_orientation (Gtk.Orientation.VERTICAL);

            var separator = new Wingpanel.Widgets.Separator ();

            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Keyboard Settings…");
            settings_button.clicked.connect (show_settings);

            var map_button = new Gtk.ModelButton ();
            map_button.text = _("Show keyboard layout");
            map_button.clicked.connect (show_keyboard_map);

            main_grid.add (layouts);
            main_grid.add (separator);
            main_grid.add (settings_button);
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

    private void update_indicator () {
        numlock.visible = settings.get_boolean ("numlock");
        capslock.visible = settings.get_boolean ("capslock");

        if (!numlock.visible && !capslock.visible && !layouts.has_layouts ()) {
            this.visible = false;
            return;
        }

        this.visible = true;
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    // Temporal workarround for Greeter crash
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION)
        return null;
    debug ("Activating Keyboard Indicator");
    var indicator = new Keyboard.Indicator ();
    return indicator;
}
