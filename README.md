# Wingpanel Keyboard Indicator
[![l10n](https://l10n.elementary.io/widgets/wingpanel/wingpanel-indicator-keyboard/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-keyboard)

## Building and Installation

You'll need the following dependencies:

* gobject-introspection
* libglib2.0-dev
* libgranite-dev
* libwingpanel-2.0-dev
* libxml2-dev
* meson
* valac
    
Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja
    
To install, use `ninja install`

    sudo ninja install
