#!/bin/sh
# A single script which will:
# - open Chromium browser if it is not running
# - focus an existing Chromium instance
# - open a speed dial page to new tab if no URL given
# - open the given URL or a new Chromium window with newwindow parameter

# Chromium executable name varies between systems.
[ "$(which chromium-browser 2>/dev/null)" ] && executable="chromium-browser"
[ ! "$executable" ] && [ "$(which chromium 2>/dev/null)" ] && executable="chromium"
[ ! "$executable" ] && echo "Chromium not found." && exit 1

focuswin=$(wmctrl -l | grep -e "Chromium" | tail -n 1 | cut -f 1 -d ' ')
if [ "$focuswin" ]
then
    wmctrl -i -a $focuswin
fi

if [ "$1" = "newwindow" ]
then
    $executable
    exit
elif [ "$#" -eq 1 ]
then
    $executable "$1"
elif [ ! "$(ps -ef | grep chromium-browser | grep -v grep)" ]
then
    $executable
else
    # To open a blank page: $executable about:blank
    # Instead of opening a blank page, use Ctrl+t new tab shortcut to open speed dial page.
    # Assuming Win+w is the shortcut for this script, keyup w first.
    # We first have to sleep for a tiny bit for the window to get focus.
    sleep 0.15 || sleep 1
    xdotool keyup w && xdotool keyup super && xdotool key ctrl+t
fi
