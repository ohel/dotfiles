#!/bin/sh
# Connect to IP address $1 with username $2 and password $3, and consider it a Windows host if $4 is "win[dows]".
# Or, just use the default values, in which case $1 may be "win[dows]" too.

sound_params=""
if [ ! "$(ps -e | grep pulseaudio)" ]
then
    sound_params=":sys:alsa"
fi

cliparams_win="+fonts +window-drag /cert-ignore /kbd:Finnish /sec:nla /bpp:32 /sound$sound_params /microphone$sound_params"
cliparams_other="/bpp:24"

default_ip=10.0.1.10
if [ "$1" = "win" || "$1" = "windows" ]
then
    os="windows"
    ip=$default_ip
else
    ip=${1:-$default_ip}
fi
user=${2:-panther}
pass=${3:-panther}

if [ "$4" = "win" || "$4" = "windows" ]
then
    os="windows"
fi

if [ "$os" = "windows" ]
then
    cliparams=$cliparams_win
else
    cliparams=$cliparams_other
fi

panelheight=$(xwininfo -id $(wmctrl -l | grep xfce4-panel | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(xwininfo -root | grep Width | cut -f 2 -d ":" | tr -d -c [:digit:])
rootwidth=$(($rootwidth>1920?1920:$rootwidth))
rootheight=$(xwininfo -root | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
rootheight=$(($rootheight>1200?1200:$rootheight))
width=$rootwidth
height=$(expr $rootheight - ${panelheight:-0})

xfreerdp /v:$ip /size:"$width"x"$height" /network:lan -decorations +clipboard -grab-keyboard /u:$user /p:$pass $cliparams
