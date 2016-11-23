#!/bin/bash
# Sometimes when using cheap remote keyboard devices, they like to add an extra joystick device. This script may be used to remove such device on udev rule match.
# Need to run as root.

# If arguments given, remove devices (normally the original joystick device).
if test "empty$1" != "empty"
then
    rm /dev/$1 &
    exit
fi
