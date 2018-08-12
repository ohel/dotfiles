# Source this file to quickly set default ALSA device.
if [ "$#" = 0 ]; then
    echo "Usage: source alsadevice.sh <device>"
    echo ""
    echo "Example devices:"
    echo "eq"
    echo "hda"
    echo "hdmi"
    echo "hifi"
    echo "loop (loop_playback_in_mix)"
    echo "null"
    echo "wav"
    echo ""
else
    pcm="$1"
    if [ "$pcm" = "hdmi" ]; then
        ctl="hdmi_hw"
    elif [ "$pcm" = "hifi" ]; then
        ctl="hifi"
    elif [ "$pcm" = "loop" ]; then
        pcm="loop_playback_in_mix"
        ctl="loop"
    fi
 
    export ALSA_OVERRIDE_PCM=$pcm
    if [ "X$ctl" != "X" ]; then
        export ALSA_OVERRIDE_CTL=$ctl
    fi
fi
