#!/bin/sh
# Play a dummy sound that software volume control device is visible for volumeicon. Before the device is used, it might not be visible. For recording dummy sound, prefer null device if found, default otherwise.

ALSA_DEVICE=softvol

null_dev=$(aplay -L | grep ^null$)
[ "$null_dev" ] && null_dev="-D $null_dev"
arecord -q -f cd -s 1 $null_dev | aplay -q -D $ALSA_DEVICE

# Force the correct corresponding hardware control device in case system default is something else.
env ALSA_DEFAULT_CTL="$ALSA_DEVICE" volumeicon &
