#!/bin/sh
# A script for udev rule to run when removing a Saitex gamepad.
# It cleans up symlinks created by the adding script.
# Need to run as root.

rm -rf /dev/input/saitek-xbox360-gamepad
pid=$(ps -ef | grep xboxdrv | grep saitek | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
[ "$pid" ] && kill $pid && sleep 1

pid=$(ps -ef | grep xboxdrv | grep saitek | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
[ "$pid" ] && kill -9 $pid
