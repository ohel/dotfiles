#!/bin/sh
# Two ways to enable or disable an Elan touchpad.

#id=$(xinput | grep Elan | cut -f 2 -d '=' | cut -f 1)
#
#status=$(xinput list-props "$id" | grep "Device Enabled" | grep -Eo '.$')
#if [ $status = 0 ]
#then
#    xinput set-prop "$id" "Device Enabled" 1
#else 
#    xinput set-prop "$id" "Device Enabled" 0
#fi

if [ "$(lsmod | grep elan_i2c)" ]
then
    sudo modprobe -r elan_i2c
else
    sudo modprobe elan_i2c
fi
