#!/bin/sh
# Sometimes when using cheap remote keyboard devices, they like to add an extra joystick device. This script may be used to remove such device on udev rule match.
# Need to run as root.

# If arguments given, remove devices (normally the original joystick device).
[ "$1" ] && rm /dev/$1 &
