#!/bin/bash

# Need to run as root.

# This script starts up xboxdrv for Saitek Cyborg Rumble Pad, creates symlink and sets read permission to new evdev.

configfile=/opt/xboxdrv/current_saitek

if [ -e $configfile ]
then
    opts="-c $configfile"
fi
ls -1 /dev/input/event* > /dev/shm/xboxdrv_oldevdev.txt
/usr/bin/xboxdrv --silent --device-by-path $1:$2 --type xbox360 --led 6 $opts &>/dev/null &

# Wait for 1 second for xboxdrv to create the js device.
sleep 1
if test "X" == "X$(find /dev/input/ -maxdepth 1 -name "js*" | head -1)"
then
    # Something went wrong.
    exit
fi

# Create symlink for the just created joystick device.
ln -sf $(ls -1 --sort=t /dev/input/js* | head -n 1) /dev/input/saitek-xbox360-gamepad

# Find new evdev by comparing old evdev list with new one.
ls -1 /dev/input/event* > /dev/shm/xboxdrv_newevdev.txt
newevdev=$(comm -3 /dev/shm/xboxdrv_oldevdev.txt /dev/shm/xboxdrv_newevdev.txt | tr -d [:blank:])
if test "X$newevdev" != "X"
then
    chmod a+r $newevdev
fi
rm /dev/shm/xboxdrv_oldevdev.txt
rm /dev/shm/xboxdrv_newevdev.txt
