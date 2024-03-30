#!/usr/bin/sh
# Resize current active window according to some rules.
# For now, the window must be a Remmina (RDP) window.
# The sizes of the window will be cycled through the following list: [1920x1080, 2560x1440, 3840x2160]
# Max height is the screen height minus panel, max width is screen width.

rdp_win_class="org.remmina.Remmina.org.remmina.Remmina"

active_win_id_dec=$(xdotool getactivewindow)
active_win_id_hex=$(echo "obase=16; $active_win_id_dec" | bc)
active_win_class=$(wmctrl -lx | grep -i "0x[0]*$active_win_id_hex" | tr -s ' ' | cut -f 3 -d ' ')

# Only resize RDP windows.
[ ! "$(echo "$rdp_win_class" | grep "$active_win_class")" ] && exit 1

root_width=$(xwininfo -root | grep Width | cut -f 2 -d ":" | tr -d -c [:digit:])
root_height=$(xwininfo -root | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
panel_height=$(xwininfo -id $(wmctrl -l | grep xfce4-panel | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:] 2>/dev/null)
max_height=$(expr $root_height - ${panel_height:-0})

width=$(xwininfo -id $active_win_id_dec | grep Width: | tr -d ' ' | cut -f 2 -d ':')
height=$(xwininfo -id $active_win_id_dec | grep Height: | tr -d ' ' | cut -f 2 -d ':')

match=""
if [ "$width" -eq 3840 ]
then
    match="found"
    width=1920
    height=1080
fi

if [ ! "$match" ] && [ "$width" -eq 1920 ]
then
    match="found"
    width=2560
    height=1440
fi

if [ ! "$match" ] && [ "$width" -eq 2560 ]
then
    match="found"
    width=3840
    height=2160
fi

if [ ! "$match" ]
then
    width=$root_width
    height=$root_height
fi

[ $width -gt $root_width ] && width=$root_width
[ $height -gt $max_height ] && height=$max_height

wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
wmctrl -r :ACTIVE: -e 0,-1,-1,$width,$height
