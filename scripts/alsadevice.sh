#!/usr/bin/sh
# Source this file to quickly set default ALSA device.

if [ "$#" = 0 ]
then
    echo "Usage: . alsadevice.sh <device>"
    echo ""
    echo "Example devices:"
    echo "eq"
    echo "hda"
    echo "hdmi (hdmi_out)"
    echo "hifi"
    echo "loop (loop_playback_in_mix)"
    echo "null"
    echo "wav"
    echo ""
else
    pcm="$1"
    [ "$1" = "hdmi" ] && pcm="hdmi_out" && ctl="hdmi_hw"
    [ "$1" = "hifi" ] && ctl="hifi"
    [ "$1" = "loop" ] && pcm="loop_playback_in_mix" && ctl="loop"

    export ALSA_DEFAULT_PCM=$pcm
    [ "$ctl" ] && export ALSA_DEFAULT_CTL=$ctl
fi
