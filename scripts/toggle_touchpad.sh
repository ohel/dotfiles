#!/usr/bin/sh
# Enable or disable a touchpad. Do this via kernel module if Elan touchpad or via xinput if Synaptics.

if [ "$(lsmod | grep elan_i2c)" ]
then
    sudo modprobe -r elan_i2c
    command -v notify-send >/dev/null && notify-send -h int:transient:1 "Removed touchpad module" -t 500
else
    synaptics_id=$(xinput | grep Synaptics | cut -f 2 -d '=' | cut -f 1)
    [ "$synaptics_id" ] && status=$(xinput list-props "$synaptics_id" | grep "Device Enabled" | grep -o ".$")

    if [ ! "$status" ]
    then
        sudo modprobe elan_i2c || exit 1
        command -v notify-send >/dev/null && notify-send -h int:transient:1 "Added touchpad module" -t 500
    else
        enabled=0 && [ $status = 0 ] && enabled=1
        xinput set-prop "$synaptics_id" "Device Enabled" $enabled
        command -v notify-send >/dev/null && notify-send -h int:transient:1 "Touchpad enabled: $enabled" -t 500
    fi
fi
