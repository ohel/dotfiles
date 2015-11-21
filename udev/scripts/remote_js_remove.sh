#!/bin/bash
# Need to run as root.

# If arguments given, remove devices (normally the original joystick device).
if test "empty$1" != "empty"
then
    rm /dev/$1 &
    exit
fi
