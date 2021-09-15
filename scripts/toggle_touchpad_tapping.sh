#!/bin/sh
# Toggles an Elan, Alps etc. touchpad tap-to-click. Disable if $1 = disable.

id=$(xinput | grep -i "\(touchpad\)\|\(synaptics\)" | cut -f 2 -d '=' | cut -f 1)

status=$(xinput list-props "$id" | grep "Synaptics Tap Action" | grep -Eo '.$')
if [ "$status" = "0" ] && [ "$1" != "disable" ]
then
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 1 3 2
else
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 0 0 0
fi
