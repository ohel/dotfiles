#!/bin/sh
# A single script which will:
# - open Chromium browser if it is not running
# - focus an existing Chromium instance
# - open a speed dial page to new tab if no URL given
# - open the given URL or a new Chromium window with newwindow parameter

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
    # To open a blank page: chromium-browser about:blank
    # Instead of opening a blank page, use Ctrl+t new tab shortcut to open speed dial page.
    # Assuming Win+w is the shortcut for this script, keyup w first.
    # We first have to sleep for a tiny bit for the window to get focus.
    sleep 0.15
    xdotool keyup w && xdotool keyup super && xdotool key ctrl+t
fi
