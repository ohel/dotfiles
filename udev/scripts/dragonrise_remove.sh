#!/bin/sh
# A script for udev rule to run when removing a DragonRise gamepad.
# It cleans up symlinks created by the adding script.
# Need to run as root.

# If arguments given, remove devices (normally the original joystick device).
[ "$1" ] && rm /dev/$1 && exit

rm -rf /dev/input/dragonrise-gamepad
pid=$(ps -ef | grep xboxdrv | grep dragonrise | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
[ "$pid" ] && kill $pid && sleep 1

pid=$(ps -ef | grep xboxdrv | grep dragonrise | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
[ "$pid" ] && kill -9 $pid
