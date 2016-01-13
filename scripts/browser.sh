#!/bin/sh
focuswin=$(wmctrl -l | grep -e "Chromium" | tail -n 1 | cut -f 1 -d ' ')
if test "X$focuswin" != "X"
then
    wmctrl -i -a $focuswin
fi

if test "X$1" = "Xnewwindow"
then
    chromium-browser
    exit
elif [ "$#" -eq 1 ];
then
    chromium-browser "$1"
elif test "$(ps -ef | grep chromium-browser | grep -v grep)X" = "X"
then
    chromium-browser
else
    #chromium-browser about:blank
    # Assuming Win+w is the shortcut, keyup w first.
    xdotool keyup w && xdotool keyup Mod4 && xdotool key Ctrl+t
fi
