#!/bin/sh
# Forces either the screensaver or standby mode. The sleep is so that using a hotkey does not counter the screensaver immediately.
# DPMS must be enabled, for example using "xset dpms 900 0 0" works well with manually forcing.

sleep 1
[ "$#" = 0 ] && xset s activate
[ "$1" = "standby" ] && xset dpms force standby
