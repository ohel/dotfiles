#!/bin/sh
# Raise ($1 = "+") or lower ($1 = "-") the volume level of device $3 (default: "Virtual Master") on card $2 (default: "any") by $4 percent units (default: 5) using ALSA mixer. If card = "any", all ALSA cards are searched for the device and the first one found is used.
# Only do this if JACK is not running. If JACK is running, change ($1) the volume of a running audio player application if one is running. Otherwise do nothing.

card=${2:-any}
dev=${3:-"Virtual Master"}
volstep=${4:-5}

[ ! "$1" = "+" ] && [ ! "$1" = "-" ] && exit 1

if [ "$(ps -e | grep jackd$)" ]
then
    # Quod Libet volume control.
    ql=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet\(.py\)\?$")
    if [ "$ql" ]
    then
        [ "$1" = "+" ] && vol="--volume-up"
        [ "$1" = "-" ] && vol="--volume-down"
        [ "$vol" ] && $ql $vol
        exit 0
    fi

    spotify=$(ps -e | grep " spotify$")
    [ ! "$spotify" ] && exit 1

    current_volume=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Volume | grep -o "double [0-9].*" | cut -f 2 -d ' ')
    new_volume=$(echo "scale=2; $current_volume $1 $volstep/100" | bc)
    [ "$new_volume" ] && dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set string:org.mpris.MediaPlayer2.Player string:Volume variant:double:$new_volume
    exit 0
fi

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

new_vol=$(expr $current_vol $1 $volstep)
[ "$1" = "+" ] && [ $new_vol -gt 100 ] && new_vol=100
[ "$1" = "-" ] && [ $new_vol -lt $volstep ] && new_vol=$volstep

amixer -c $card set "$dev",0 "$new_vol"% >/dev/null

[ ! "$(which notify-send 2>/dev/null)" ] || [ ! "$DISPLAY" ] && exit 0

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

notify-send -h int:transient:1 "Volume: $new_vol" -t 500
