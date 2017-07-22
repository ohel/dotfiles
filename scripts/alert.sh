#!/bin/sh
# Play an alert sound if there is a file called alert.set in user's home directory.

wav=${1:-~/.local/share/misc/alert.wav}
alsadev=${2:-julia_aout}

if [ -e ~/alert.set ]
then
    echo $(date) >> ~/alert.hit
    # Try a specific sound device first, use default device as a fallback.
    if test "X$(aplay -q -D $alsadev $wav)" != ""
    then
        aplay -q $wav
    fi
else
    echo $(date) >> ~/alert.pass
fi
