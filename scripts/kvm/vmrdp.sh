#!/bin/sh
cliparams_win="+fonts +window-drag /cert-ignore /kbd:Finnish /sec:nla /bpp:32"
cliparams_other="/bpp:24"

ip=${1:-10.0.1.10}
user=${2:-panther}
pass=${3:-panther}
cliparams=$cliparams_other

panelheight=$(xwininfo -id $(wmctrl -l | grep xfce4-panel | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(xwininfo -root | grep Width | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(($rootwidth>1920?1920:$rootwidth))
rootheight=$(xwininfo -root | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootheight=$(($rootheight>1200?1200:$rootheight))
width=$rootwidth
height=$(expr $rootheight - $panelheight)

xfreerdp /v:$ip /size:"$width"x"$height" /network:lan -decorations +clipboard -grab-keyboard /u:$user /p:$pass $cliparams
