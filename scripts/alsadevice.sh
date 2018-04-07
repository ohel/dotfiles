# Source this file to quickly set default ALSA device.
if [ "$#" = 0 ]; then
    echo "Usage: source alsadevice.sh <device>"
    echo ""
    echo "Valid devices:"
    echo "combo (combo)"
    echo "hda   (hda)"
    echo "hdmi  (hdmi_out)"
    echo "julia (julia)"
    echo "eq    (hda_eq)"
    echo "file  (file_out)"
    echo "null"
    echo ""
else
    if [ "$1" = "combo" ]; then
        pcm="combo"
        ctl="hda_hw"
    elif [ "$1" = "hda" ]; then
        pcm="hda"
        ctl="hda_hw"
    elif [ "$1" = "hdmi" ]; then
        pcm="hdmi_out"
        ctl="hdmi_hw"
    elif [ "$1" = "julia" ]; then
        pcm="julia"
        ctl="julia_digital_hw"
    elif [ "$1" = "eq" ]; then
        pcm="hda_eq"
        ctl="hda_hw"
    elif [ "$1" = "null" ]; then
        pcm="null"
        ctl="hda_hw"
    elif [ "$1" = "file" ]; then
        pcm="file_out"
        ctl="hda_hw"
    else
        echo "Unknown device."
    fi
 
    export ALSA_DEFAULT_PCM=$pcm
    export ALSA_DEFAULT_CTL=$ctl
fi
