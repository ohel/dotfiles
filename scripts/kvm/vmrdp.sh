#!/bin/sh
cliparams_win="+fonts +window-drag /cert-ignore /kbd:Finnish /sec:nla /bpp:32"
cliparams_other="/bpp:24"

user=panther
pass=panther
ip=$1
cliparams=$cliparams_other

panelheight=$(xwininfo -id $(wmctrl -l | grep xfce4-panel | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(xwininfo -root | grep Width | cut -f 2 -d ":" | tr -d -c [:digit:])
rootheight=$(xwininfo -root | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
width=$rootwidth
height=$(expr $rootheight - $panelheight)

xfreerdp /v:$ip /size:"$width"x"$height" -decorations +clipboard -grab-keyboard /u:$user /p:$pass $cliparams
