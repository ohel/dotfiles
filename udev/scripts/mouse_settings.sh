#!/usr/bin/sh
# Configure a mouse using libinput. Run this script via a udev rule, as a specific user. Could also run this script on login since there might not have been any add device events to trigger the rule yet.

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0

# Wait for the device to initialize, especially if Bluetooth device.
sleep 2

# Button mapping and acceleration settings for Keychron M6, for all three ways of connecting it.
# Wired.
xinput set-button-map "Keychron  Keychron Link-KM" 1 12 3 4 5 6 7 10 11 2>/dev/null
xinput set-prop "Keychron  Keychron Link-KM" "libinput Accel Speed" 0.25 2>/dev/null
# Dongle.
xinput set-button-map "Keychron  Keychron M6 Lite" 1 12 3 4 5 6 7 10 11 2>/dev/null
xinput set-prop "Keychron  Keychron M6 Lite" "libinput Accel Speed" 0.25 2>/dev/null
# Bluetooth.
xinput set-button-map "Keychron M6 Lite Mouse" 1 12 3 4 5 6 7 10 11 2>/dev/null
xinput set-prop "Keychron M6 Lite Mouse" "libinput Accel Speed" 0.25 2>/dev/null
