#!/usr/bin/sh
# If using libinput as X.org driver instead of evdev, set button map and acceleration with xinput.
# Adjust according to setup and use the desktop file shortcut key to load on demand.
xinput set-button-map "Keychron Keychron M6 Lite Mouse" 1 12 3 4 5 6 7 10 11 2>/dev/null
xinput set-prop "Keychron Keychron M6 Lite Mouse" "libinput Accel Speed" 0.25 2>/dev/null
