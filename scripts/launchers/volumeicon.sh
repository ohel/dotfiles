#!/bin/sh

# Play a dummy wav so that software volume control device is visible for volumeicon.
aplay -q -D softvol ~/.local/share/misc/dummy.wav

# Override default control device to control what we really want.
ALSA_DEFAULT_CTL="julia_analog_hw" volumeicon &
