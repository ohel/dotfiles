#!/bin/sh
if test "X$1" == "newwindow"
then
    chromium-browser
    exit
elif [ "$#" -eq 1 ];
then
    chromium-browser "$1"
elif test "$(ps -ef | grep chromium-browser | grep -v grep)X" == "X"
then
    chromium-browser
fi
wmctrl -i -a $(wmctrl -l | grep -e "Chromium" | tail -n 1 | cut -f 1 -d ' ')
