/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2015-2025 elementary, Inc. (https://elementary.io)
*/

public class Keyboard.Indicator : Wingpanel.Indicator {
    public Wingpanel.IndicatorManager.ServerType server_type { get; construct; }

    private Gdk.Device device;
    private GLib.Settings settings;
    private Gtk.Box indicator_box;
    private Gtk.Revealer numlock_revealer;
    private Gtk.Revealer capslock_revealer;
    private Keyboard.Widgets.PopoverWidget popover_widget;
    private Gtk.Label layouts_icon;
    private Gtk.Revealer layouts_revealer;
    private Gtk.GestureMultiPress gesture_click;

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
            var numlock_icon = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic");

            numlock_revealer = new Gtk.Revealer () {
                child = numlock_icon,
                transition_type = SLIDE_LEFT,
                tooltip_markup = Granite.markup_accel_tooltip ({}, _("Num Lock is on"))
            };

            var capslock_icon = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic");

            capslock_revealer = new Gtk.Revealer () {
                child = capslock_icon,
                transition_type = SLIDE_LEFT,
                tooltip_markup = Granite.markup_accel_tooltip ({}, _("Caps Lock is on"))
            };

            layouts_icon = new Gtk.Label (null) {
                height_request = 20,
                width_request = 20,
                margin_top = 2,
                margin_bottom = 2,
                margin_start = 2,
                margin_end = 2
            };
            layouts_icon.add_css_class ("keyboard-icon");

            layouts_revealer = new Gtk.Revealer () {
                child = layouts_icon,
                transition_type = SLIDE_LEFT
            };

            indicator_box = new Gtk.Box (HORIZONTAL, 0) {
                valign = CENTER
            };
            indicator_box.append (numlock_revealer);
            indicator_box.append (capslock_revealer);
            indicator_box.append (layouts_revealer);

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/desktop/wingpanel/keyboard/KeyboardIcon.css");

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            settings = new GLib.Settings ("io.elementary.wingpanel.keyboard");

            device = Gdk.Display.get_default ().get_default_seat ().get_keyboard ();

            settings.changed.connect (() => {
                update_visibility ();
            });

            device.changed.connect (() => {
                update_visibility ();
            });

            gesture_click = new Gtk.GestureMultiPress (indicator_box) {
                button = Gdk.BUTTON_MIDDLE
            };

            gesture_click.pressed.connect (() => {
                popover_widget.next ();
                gesture_click.set_state (CLAIMED);
                gesture_click.reset ();
            });

            popover_widget = new Keyboard.Widgets.PopoverWidget (server_type);
            popover_widget.updated.connect (() => {
                update_visibility ();
            });

            popover_widget.updated ();
        }

        return indicator_box;
    }

    private void update_visibility () {
        layouts_icon.label = popover_widget.current_language_code[0:2];
        layouts_revealer.reveal_child = popover_widget.has_multiple_layouts () || settings.get_boolean ("always-show-layout");

        numlock_revealer.reveal_child = device.get_num_lock_state () && settings.get_boolean ("numlock");
        capslock_revealer.reveal_child = device.get_caps_lock_state () && settings.get_boolean ("capslock");

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
        return popover_widget;
    }

    public override void opened () {

    }

    public override void closed () {

    }

    private void update_tooltip () {
        string description = popover_widget.get_current_description ();
        string accel_label = Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (_("Middle-click to switch to the next layout"));

        layouts_revealer.tooltip_markup = "%s\n%s".printf (description, accel_label);
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Keyboard Indicator");
    var indicator = new Keyboard.Indicator (server_type);
    return indicator;
}
