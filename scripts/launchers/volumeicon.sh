#!/bin/sh
# Play a dummy wav so that software volume control device is visible for volumeicon.
#aplay -q -D hda_out_mix_44100_vol ~/.local/share/misc/dummy.wav
ALSA_DEFAULT_CTL="julia_analog_hw" exec volumeicon &
