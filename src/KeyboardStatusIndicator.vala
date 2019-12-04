/*
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

public class Keyboard.KeyboardStatusIndicator : Wingpanel.Indicator {
    private Gtk.Box display_widget;
    private Gtk.Box popover_widget;
    private GLib.Settings settings;
    private Gtk.Image capslock;
    private Gtk.Image numlock;
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
        settings = new GLib.Settings ("io.elementary.wingpanel.keyboard");
        keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());

        numlock = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        numlock.use_fallback = true;
        numlock.margin = 2;
        numlock.set_size_request (20, 20);
        numlock.halign = Gtk.Align.CENTER;
        numlock.valign = Gtk.Align.CENTER;

        capslock = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        capslock.use_fallback = true;
        capslock.margin = 2;
        capslock.set_size_request (20, 20);
        capslock.halign = Gtk.Align.CENTER;
        capslock.valign = Gtk.Align.CENTER;

        settings.change_event.connect (() => {
            update_indicator ();
        });

        keymap.state_changed.connect (update_indicator);
    }

    public override Gtk.Widget get_display_widget () {
        if (display_widget == null) {
            display_widget = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            display_widget.valign = Gtk.Align.CENTER;
            display_widget.pack_start (numlock, false, false);
            display_widget.pack_end (capslock, false, false);
        }

        update_indicator ();

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

    private void update_indicator () {
        if (!settings.get_boolean ("numlock") && !settings.get_boolean ("capslock")) {
            this.visible = false;

            return;
        }

        this.visible = true;
        numlock.visible = false;
        capslock.visible = false;

        if (settings.get_boolean ("numlock")){
            numlock.visible = keymap.get_num_lock_state ();
        }

        if (settings.get_boolean ("capslock")){
            capslock.visible = keymap.get_caps_lock_state ();
        }
    }

    private void show_settings () {
        close ();

        try {
            AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
        } catch (Error e) {
            warning (e.message);
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Keyboard Status Indicator");

    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    return new Keyboard.KeyboardStatusIndicator ();
}
