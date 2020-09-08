#!/bin/sh
# Raise ($1: + or up) or lower ($1: - or down) the volume level of "Virtual Master" (or $3) on card "HDA" (or $2) by 13/256 steps (or $4) using ALSA mixer.

card=${2:-HDA}
dev=${3:-"Virtual Master"}
volstep=${4:-13} # 13/256 = about 5%

current_vol=$(amixer -c$card get "$dev",0 | grep "Front Left:" | sed "s/[^0-9]*\([0-9]*\).*/\1/")
[ ! "$current_vol" ] && echo "Control not found." && exit 1


if [ "$1" = "up" ] || [ "$1" = "+" ]
then
    new_vol=$(expr $current_vol + $volstep)
    [ $new_vol -gt 255 ] && new_vol=255
elif [ "$1" = "down" ] || [ "$1" = "-" ]
then
    new_vol=$(expr $current_vol - $volstep)
    [ $new_vol -lt $volstep ] && new_vol=$volstep
fi

volper=$(amixer -c$card set "$dev",0 $new_vol | grep "Front Left:.*" | grep -o "[0-9]*%")
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Volume: $volper" -t 500
