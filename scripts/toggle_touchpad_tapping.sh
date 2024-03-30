#!/usr/bin/sh
# Toggles an Elan, Alps etc. touchpad tap-to-click. Disable if $1 = disable.

id=$(xinput | grep -i "\(touchpad\)\|\(synaptics\)" | cut -f 2 -d '=' | cut -f 1)
[ ! "$id" ] && echo "Touchpad not found." && exit 1

status=$(xinput list-props "$id" | grep "Synaptics Tap Action" | grep -Eo '.$')
if [ "$status" = "0" ] && [ "$1" != "disable" ]
then
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 1 3 2
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Tapping enabled" -t 500
else
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 0 0 0
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Tapping disabled" -t 500
fi
