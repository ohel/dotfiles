#!/bin/sh
# Enable or disable a touchpad. Do this via kernel module if Elan touchpad or via xinput if Synaptics.

if [ "$(lsmod | grep elan_i2c)" ]
then
    sudo modprobe -r elan_i2c
else
    synaptics_id=$(xinput | grep Synaptics | cut -f 2 -d '=' | cut -f 1)
    [ "$synaptics_id" ] && status=$(xinput list-props "$synaptics_id" | grep "Device Enabled" | grep -o ".$")

    if [ ! "$status" ]
    then
        sudo modprobe elan_i2c
    else
        [ $status = 0 ] && xinput set-prop "$synaptics_id" "Device Enabled" 1
        [ $status = 1 ] && xinput set-prop "$synaptics_id" "Device Enabled" 0
    fi
fi
