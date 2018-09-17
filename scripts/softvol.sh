#!/bin/sh
# Raise (parameter: +) or lower (parameter: -) the "Soft Master" volume level using ALSA mixer.

current_vol=$(amixer -cPCH get 'Soft Master',0 | grep "Front Left:" | sed "s/[^0-9]*\([0-9]*\).*/\1/")

if [ "$1" = "up" || "$1" = "+" ]
then
    new_vol=$(expr $current_vol + 5)
    [ $new_vol -gt 255 ] && new_vol=255
elif [ "$1" = "down" || "$1" = "-" ]
then
    new_vol=$(expr $current_vol - 5)
    [ $new_vol -lt 5 ] && new_vol=5
fi

amixer -cPCH set 'Soft Master',0 $new_vol
