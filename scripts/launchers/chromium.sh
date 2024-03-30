#!/usr/bin/sh
# A single script that will:
# - open Chromium browser if it is not running
# - focus an existing Chromium instance
# - open the new tab page if no URL is given
# - open the given URL or a new Chromium window if $1 = newwindow

# Since version 91 the scale is computed automatically.
scale="env GDK_DPI_SCALE=1 GDK_SCALE=1"

# Chromium executable name varies between systems.
[ "$(which chromium-browser 2>/dev/null)" ] && executable="chromium-browser"
[ ! "$executable" ] && [ "$(which chromium 2>/dev/null)" ] && executable="chromium"
[ ! "$executable" ] && echo "Chromium not found." && exit 1

focuswin=$(wmctrl -l | grep -e "Chromium" | tail -n 1 | cut -f 1 -d ' ')
[ "$focuswin" ] && wmctrl -i -a $focuswin

if_running=""
[ "$1" = "ifrunning" ] && if_running=1 && shift

url=$1

file_url_invalid=""
if [ "$(echo "$1" | cut -c -7)" = "file://" ]
then
    # Check if file exists.
    userhome=$(echo $HOME | sed "s/\\//\\\\\//g")
    filename=$(echo "$1" | cut -c 8- | sed "s/^~/$userhome/")
    [ ! -e "$filename" ] && file_url_invalid=1 || url="file://$filename"
fi

[ "$1" = "newwindow" ] && $scale $executable && exit 0

running_exe=$(ps -ef | grep $executable | grep -v grep)

if [ "$if_running" ] && [ "$running_exe" ] && [ ! "$file_url_invalid" ]
then
    $scale $executable "$url"
elif [ ! "$if_running" ] && [ "$url" ] && [ ! "$file_url_invalid" ]
then
    $scale $executable "$url"
elif [ ! "$running_exe" ]
then
    $scale $executable
else
    # To open a blank page: $executable about:blank
    # Instead of opening a blank page, use Ctrl+t to open "new tab" page, which may be for example a speed dial extension page.
    # Assuming Win+w (Mod4+w) is the shortcut for this script, keyup w first.
    # We first have to sleep for a tiny bit for the window to get focus.
    sleep 0.15 || sleep 1
    xdotool keyup w && xdotool keyup super && xdotool key ctrl+t
fi
