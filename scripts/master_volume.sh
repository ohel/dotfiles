#!/bin/sh
# Raise ($1 = "+") or lower ($1 = "-") the volume level of device $3 (default: "Virtual Master") on card $2 (default: "any") by $4 integer percent units (default: 5) using ALSA mixer. If card = "any", all ALSA cards are searched for the device and the first one found is used.
# If PulseAudio is running, change the volume of the default sink instead.
# If JACK is running, change ($1) the volume of a running audio player application if one is running. Otherwise do nothing.

card=${2:-any}
dev=${3:-"Virtual Master"}
vol_step=${4:-5}

[ ! "$1" = "+" ] && [ ! "$1" = "-" ] && exit 1

# PulseAudio volume control.
if [ "$(ps -e | grep pulseaudio$)" ]
then
    default_sink=$(pacmd list-sinks | grep "\* index" | cut -f 2 -d ':' | tr -d ' ')
    [ ! "$default_sink" ] && exit 1

    current_vol=$(pactl get-sink-volume $default_sink | grep -o "[0-9]\{1,3\}%" | head -n 1 | tr -d '%')
    new_vol=$(echo "$current_vol $1 $vol_step" | bc)
    [ "$1" = "+" ] && [ $new_vol -gt 100 ] && new_vol=100
    [ "$1" = "-" ] && [ $new_vol -lt $vol_step ] && new_vol=$vol_step

    pactl set-sink-volume $default_sink "$new_vol"%
    exit 0
fi

# Application volume control.
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

    # Spotify volume control.
    [ ! "$(ps -e | grep " spotify$")" ] && exit 1

    current_vol=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Volume | grep -o "double [0-9].*" | cut -f 2 -d ' ')
    new_vol=$(echo "scale=2; $current_vol $1 $vol_step/100" | bc)
    [ ! "$new_vol" ] && exit 1
    new_vol_percent=$(echo "$new_vol * 100" | bc | cut -f 1 -d '.')
    [ "$1" = "+" ] && [ $new_vol_percent -gt 100 ] && new_vol=1.0
    [ "$1" = "-" ] && [ $new_vol_percent -lt $vol_step ] && new_vol=$(echo "scale=2; $vol_step/100" | bc)

    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set string:org.mpris.MediaPlayer2.Player string:Volume variant:double:$new_vol
    exit 0
fi

# ALSA volume control.
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

new_vol=$(expr $current_vol $1 $vol_step)
[ "$1" = "+" ] && [ $new_vol -gt 100 ] && new_vol=100
[ "$1" = "-" ] && [ $new_vol -lt $vol_step ] && new_vol=$vol_step

amixer -c $card set "$dev",0 "$new_vol"% >/dev/null

[ ! "$(which notify-send 2>/dev/null)" ] || [ ! "$DISPLAY" ] && exit 0

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

notify-send -h int:transient:1 "Volume: $new_vol" -t 500
