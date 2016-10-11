#!/bin/sh
# Toggles an Elan touchpad tapping.

id=$(xinput | grep Elan | cut -f 2 -d '=' | cut -f 1)

status=$(xinput list-props "$id" | grep "Synaptics Tap Action" | grep -Eo '.$')
if [ $status = 0 ]; then 
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 1 3 2
else 
    xinput set-prop "$id" "Synaptics Tap Action" 2 3 0 0 0 0 0
fi
