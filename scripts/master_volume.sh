#!/bin/sh
# Raise ($1 = "+" or "up") or lower ($1 = "-" or "down") the volume level of device $3 (default: "Virtual Master") on card $2 (default: "any") by $4 percent units (default: 5) using ALSA mixer. If card = "any", all ALSA cards are searched for the device and the first one found is used.
# Only do this if JACK is not running. If JACK is running, change ($1) the volume of a running audio player application if one is running. Otherwise do nothing.

card=${2:-any}
dev=${3:-"Virtual Master"}
volstep=${4:-5}

if [ "$(ps -e | grep jackd$)" ]
then
    # Quod Libet volume control.
    ql=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet\(.py\)\?$")
    if [ "$ql" ]
    then
        vol="--volume-down" && [ "$1" = "+" ] && vol="--volume-up"
        $ql $vol
        exit 0
    fi

    spotify=$(ps -e | grep " spotify$")
    [ ! "$spotify" ] && exit 1

    # Spotify's volume property seems to be broken, dbus doesn't work.
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set string:org.mpris.MediaPlayer2.Player string:Volume variant:double:1.0

    # Instead, find the Spotify window and emulate scroll wheel over volume slider.
    spotifywin=$(wmctrl -lx | grep -i "spotify.spotify" | cut -f 1 -d ' ')

    xdotool windowmap $spotifywin
    xdotool windowraise $spotifywin
    xdotool windowstate --add MAXIMIZED_VERT $spotifywin
    xdotool windowstate --add MAXIMIZED_HORZ $spotifywin

    xdotool mousemove 3650 2000 # Assume 4K resolution.
    xdotool windowraise $spotifywin
    vol=5 && [ "$1" = "+" ] && vol=4
    xdotool click $vol
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

[ ! "$(which notify-send 2>/dev/null)" ] || [ ! "$DISPLAY" ] && exit 0

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

notify-send -h int:transient:1 "Volume: $new_vol" -t 500
