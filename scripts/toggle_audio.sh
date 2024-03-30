#!/usr/bin/sh
# A generic audio toggle script to toggle digital interface, audio mute state or volume levels.

[ -e ~/.scripts_extra/toggle_audio.sh ] && . ~/.scripts_extra/toggle_audio.sh

# Toggle ALSA S/PDIF.
if [ "$1" = "spdif" ]
then
    is_on=""
    card=${2:-Generic}
    amixer -c$card get 'IEC958' | grep off > /dev/null || is_on="1"
    if [ "$is_on" ]
    then
        amixer -c$card set 'IEC958' 'off' > /dev/null
        state="OFF"
    else
        amixer -c$card set 'IEC958' 'on' > /dev/null
        state="ON"
    fi

    echo "Set S/PDIF: $state"
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "S/PDIF: $state" -t 500
    exit 0
fi

# Toggle PulseAudio default sink muted state.
if [ "$(ps -e | grep pulseaudio$)" ]
then
    default_sink=$(pacmd list-sinks | grep "\* index" | cut -f 2 -d ':' | tr -d ' ')
    [ ! "$default_sink" ] && exit 1

    muted=$(pactl get-sink-mute $default_sink | cut -f 2 -d ':' | tr -d ' ')
    new_state="no"
    [ "$muted" = no ] && new_state="yes"

    pactl set-sink-mute $default_sink "$new_state"
    exit 0
fi

# Toggle ALSA audio current volume/5% volume.
card=${1:-M4}
dev=${2:-"Virtual Master"}
store_file=~/.cache/virtual_master_volume

if [ -e $store_file ]
then
    new_vol=$(cat $store_file)
    rm $store_file
else
    current_vol=$(amixer -c $card get "$dev",0 | grep "Front Left:" | sed "s/.*\[\([0-9]*\)%\].*/\1/")
    new_vol=5
    echo $current_vol > $store_file
fi

amixer -c $card set "$dev",0 "$new_vol"% >/dev/null

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Volume: $new_vol" -t 500
