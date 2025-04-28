/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2015-2025 elementary, Inc. (https://elementary.io)
*/

public class Keyboard.Indicator : Wingpanel.Indicator {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private Gdk.Keymap keymap;
    private GLib.Settings settings;
    private Gtk.Box indicator_box;
    private Gtk.Box main_box;
    private Gtk.Revealer numlock_revealer;
    private Gtk.Revealer capslock_revealer;
    private Keyboard.Widgets.LayoutManager layouts;
    private Keyboard.Widgets.KeyboardIcon layouts_icon;
    private Gtk.Revealer layouts_revealer;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        Object (
            code_name: Wingpanel.Indicator.KEYBOARD,
            server_type: server_type
        );
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_box == null) {
            var numlock_icon = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            numlock_revealer = new Gtk.Revealer () {
                child = numlock_icon,
                transition_type = SLIDE_LEFT,
                tooltip_markup = Granite.markup_accel_tooltip ({}, _("Num Lock is on"))
            };

            var capslock_icon = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            capslock_revealer = new Gtk.Revealer () {
                child = capslock_icon,
                transition_type = SLIDE_LEFT,
                tooltip_markup = Granite.markup_accel_tooltip ({}, _("Caps Lock is on"))
            };

            layouts_icon = new Keyboard.Widgets.KeyboardIcon ();

            layouts_revealer = new Gtk.Revealer () {
                child = layouts_icon
                transition_type = SLIDE_LEFT
            };

            indicator_box = new Gtk.Box (HORIZONTAL, 0) {
                valign = CENTER
            };
            indicator_box.add (numlock_revealer);
            indicator_box.add (capslock_revealer);
            indicator_box.add (layouts_revealer);

            settings = new GLib.Settings ("io.elementary.wingpanel.keyboard");
            keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());

            settings.changed.connect (() => {
                update_visibility ();
            });

            keymap.state_changed.connect (() => {
                update_visibility ();
            });

            indicator_box.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    layouts.next ();
                    return Gdk.EVENT_STOP;
                }
                return Gdk.EVENT_PROPAGATE;
            });

            layouts = new Keyboard.Widgets.LayoutManager ();
            layouts.updated.connect (() => {
                update_visibility ();
            });

            layouts.updated ();
        }

        return indicator_box;
    }

    private void update_visibility () {
        layouts_icon.label = layouts.current_language_code[0:2];
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
        if (main_box == null) {
            var separator = new Gtk.Separator (HORIZONTAL) {
                margin_top = 3,
                margin_bottom = 3
            };

            var map_button = new Gtk.ModelButton () {
                text = _("Show Keyboard Layout")
            };

            main_box = new Gtk.Box (VERTICAL, 0);
            main_box.add (layouts);
            main_box.add (separator);
            main_box.add (map_button);

            if (server_type != Wingpanel.IndicatorManager.ServerType.GREETER) {
                var settings_button = new Gtk.ModelButton () {
                    text = _("Keyboard Settings…")
                };
                settings_button.clicked.connect (show_settings);

                main_box.add (settings_button);
            }

            main_box.show_all ();

            map_button.clicked.connect (show_keyboard_map);
        }

        return main_box;
    }

    public override void opened () {

    }

    public override void closed () {

    }

    private void show_settings () {
        close ();

        try {
            AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
        } catch (Error e) {
            warning (e.message);
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
        string description = layouts.get_current_description ();
        string accel_label = Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (_("Middle-click to switch to the next layout"));

        layouts_revealer.tooltip_markup = "%s\n%s".printf (description, accel_label);
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Keyboard Indicator");
    var indicator = new Keyboard.Indicator (server_type);
    return indicator;
}
