# Wingpanel Keyboard Indicator
[![Translation status](https://l10n.elementary.io/widgets/wingpanel/-/wingpanel-indicator-keyboard/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-keyboard)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gobject-introspection
* libglib2.0-dev
* libgranite-dev
* libwingpanel-dev
* libxml2-dev
* meson (>= 0.58.0)
* valac
    
Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja
    
To install, use `ninja install`

    sudo ninja install
