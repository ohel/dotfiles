#!/bin/bash
# A script for udev rule to run when removing a Drangonrise gamepad.
# It cleans up symlinks created by the adding script.
# Need to run as root.

# If arguments given, remove devices (normally the original joystick device).
if test "empty$1" != "empty"
then
    rm /dev/$1
    exit
fi

rm -rf /dev/input/dragonrise-gamepad
pid=$(ps -ef | grep xboxdrv | grep dragonrise | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if ! [ "X$pid" == "X" ]
then
    kill $pid
    sleep 1
fi
pid=$(ps -ef | grep xboxdrv | grep dragonrise | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if ! [ "X$pid" == "X" ]
then
    kill -9 $pid
fi
