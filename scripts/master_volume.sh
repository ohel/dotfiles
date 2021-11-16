#!/bin/sh
# Raise ($1 = "+" or "up") or lower ($1 = "-" or "down") the volume level of device $3 (default: "Virtual Master") on card $2 (default: "any") by $4 percentage (default: 5) using ALSA mixer. If card = "any", all ALSA cards are searched for the device and the first one found is used.

card=${2:-any}
dev=${3:-"Virtual Master"}
volstep=${4:-5}

if [ "$card" = "any" ]
then
    for cardnum in $(cat /proc/asound/cards | grep -o "[0-9 ]*\[" | tr -d -c "[:digit:]\n")
    do
        if [ "$(amixer scontrols -c $cardnum | grep "$dev")" ]
        then
            card=$cardnum
            break
        fi
    done
fi

[ "$card" = "any" ] && echo "Control not found from any device." && exit 1

current_vol=$(amixer -c $card get "$dev",0 | grep "Front Left:" | sed "s/.*\[\([0-9]*\)%\].*/\1/")
[ ! "$current_vol" ] && echo "Could not get current volume." && exit 1

if [ "$1" = "up" ] || [ "$1" = "+" ]
then
    new_vol=$(expr $current_vol + $volstep)
    [ $new_vol -gt 100 ] && new_vol=100
elif [ "$1" = "down" ] || [ "$1" = "-" ]
then
    new_vol=$(expr $current_vol - $volstep)
    [ $new_vol -lt $volstep ] && new_vol=$volstep
fi

amixer -c $card set "$dev",0 "$new_vol"% >/dev/null


[ ! "$(which notify-send 2>/dev/null)" ] && exit 0

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

notify-send -h int:transient:1 "Volume: $new_vol" -t 500
