#!/usr/bin/sh
# Raise ($1 = "+") or lower ($1 = "-") the volume level of device $3 (default: "Master") on card $2 (default: "any") by $4 integer percent units (default: 5) using ALSA mixer. If card = "any", all ALSA cards are searched for the device and the first one found is used. Capabilities with just volume (not pvolume or others) are preferred so that software volume control takes precedence over hardware. The last channel found for the device is used for control.
# If changing ALSA volume fails (perhaps deliberately), card is set to "any", and PulseAudio is running, change the volume of the default PulseAudio sink instead. Same happens if card is set to "PulseAudio".
# If JACK is running, change ($1) the volume of a running audio player application if one is running. Otherwise do nothing (no ALSA or PulseAudio volume control).
# If ~/.config/master_volume_dev exists, that file is used for ALSA device by default unless given as $3. Use "PulseAudio" as device to always force PulseAudio.

card=${2:-any}
dev=${3:-"Master"}
vol_step=${4:-5}

[ ! "$1" = "+" ] && [ ! "$1" = "-" ] && exit 1
[ ! "$3" ] && [ -e ~/.config/master_volume_dev ] && dev=$(cat ~/.config/master_volume_dev)

do_pulse="" && [ "$dev" = "PulseAudio" ] && do_pulse=yes

# Application volume control if JACK running.
if [ ! "$do_pulse" ] && [ "$(ps -e | grep jackd$)" ]
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
    ! ps -e | grep " spotify$" && exit 1

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
if [ ! "$do_pulse" ] && [ "$card" = "any" ]
then
    for cardnum in $(cat /proc/asound/cards | grep -o "[0-9 ]*\[" | tr -d -c "[:digit:]\n")
    do
        if [ "$(amixer scontrols -c $cardnum | grep "$dev")" ]
        then
            # First try to find a card with just volume capability.
            if [ "$(amixer -c $cardnum get "$dev",0 | grep "Capabilities: volume")" ]
            then
                card=$cardnum
                break
            else
                altcard=$cardnum
            fi
        fi
    done
    [ "$card" = "any" ] && [ "$altcard" ] && card=$altcard
fi

# If ALSA fails, we'll do PulseAudio volume control instead.
[ ! "$do_pulse" ] && [ "$card" = "any" ] && echo "Control not found from any ALSA device." && do_pulse=yes

if [ ! "$do_pulse" ]
then
    channel=$(amixer -c $card get "$dev",0 | tail -n 1 | cut -f 1 -d ':' | sed "s/^[ ]*//")
    current_vol=$(amixer -M -c $card get "$dev",0 | grep "$channel:" | sed "s/.*\[\([0-9]*\)%\].*/\1/")
    [ ! "$current_vol" ] && echo "Could not get current volume from ALSA." && do_pulse=yes
fi

# PulseAudio (PipeWire) volume control. This also controls for example Spotify's volume, as it is locked to PulseAudio volume.
if [ "$do_pulse" ]
then
    # If PipeWire was running instead of PulseAudio, pacmd would fail.
    if [ "$(pactl info | grep -i pipewire)" ]
    then
        default_sink="@DEFAULT_SINK@"
    else
        default_sink=$(pacmd list-sinks | grep "\* index" | cut -f 2 -d ':' | tr -d ' ')
    fi
    current_vol=$(pactl get-sink-volume $default_sink | grep -o "[0-9]\{1,3\}%" | head -n 1 | tr -d '%')
fi

new_vol=$(echo "$current_vol $1 $vol_step" | bc)

# If step <= 10% and new volume less than 10%, use half step size, rounded down.
# For example, a step of 5% results in volume change of 2% in the 0-10% range for finer tuning.
use_new_step=""
[ "$1" = "-" ] && [ $new_vol -lt 10 ] && use_new_step=1
[ "$1" = "+" ] && [ $current_vol -lt 10 ] && use_new_step=1
[ "$use_new_step" ] && [ $vol_step -le 10 ] && vol_step=$(expr $vol_step / 2)
[ "$use_new_step" ] && new_vol=$(echo "$current_vol $1 $vol_step" | bc)

# If step <= 10%, force minimum volume equal to step size.
[ "$1" = "-" ] && [ $vol_step -le 10 ] && [ $new_vol -lt $vol_step ] && new_vol=$vol_step
[ "$1" = "-" ] && [ $new_vol -lt 0 ] && new_vol=0
[ "$1" = "+" ] && [ $new_vol -gt 100 ] && new_vol=100

[ ! "$do_pulse" ] && amixer -M -c $card set "$dev",0 "$new_vol"% >/dev/null
[ "$do_pulse" ] && pactl set-sink-volume $default_sink "$new_vol"%

[ ! "$(which notify-send 2>/dev/null)" ] || [ ! "$DISPLAY" ] && exit 0

# Close previous notifications so that new volume is displayed immediately.
winid=$(xwininfo -name Notification 2>/dev/null | head -n 2 | grep -o "0x[^ ]*")
[ "$winid" ] && wmctrl -i -c $winid 2>/dev/null

[ "$do_pulse" ] && msg="PulseAudio: $new_vol%" || msg="ALSA: $new_vol%"
notify-send -i multimedia-volume-control -h int:transient:1 -t 500 "$msg"
