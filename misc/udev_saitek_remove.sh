#!/bin/bash
# Need to run as root.

rm -rf /dev/input/saitek-xbox360-gamepad
pid=$(ps -ef | grep xboxdrv | grep saitek | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if ! [ "X$pid" == "X" ]
then
    kill $pid
    sleep 1
fi
pid=$(ps -ef | grep xboxdrv | grep saitek | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if ! [ "X$pid" == "X" ]
then
    kill -9 $pid
fi
