#!/bin/sh
# Forces either the screensaver or standby mode. The sleep is so that using a hotkey does not counter the screensaver immediately.
# DPMS must be enabled, for example using "xset dpms 900 0 0" works well with manually forcing.

sleep 0.5
if [ "$#" = 0 ]; then
    xset s activate
fi
if [ "$1" = "standby" ]; then
    xset dpms force standby
fi
