#!/bin/sh
panelheight=$(xwininfo -id $(wmctrl -l | grep xfce4-panel | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(xwininfo -root | grep Width | cut -f 2 -d ":" | tr -d -c [:digit:])
rootheight=$(xwininfo -root | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
width=$rootwidth
height=$(expr $rootheight - $panelheight)
xfreerdp /u:panther /p:panther /v:$1 /size:"$width"x"$height" /bpp:24 -decorations +clipboard -grab-keyboard

