#!/bin/sh

# Play a dummy wav so that software volume control device is visible for volumeicon. Before the device is used, it might not be visible.
aplay -q -D hda_softvol ~/.local/share/misc/dummy.wav

# Force the correct corresponding hardware control device.
env ALSA_DEFAULT_CTL="hda_hw" volumeicon &
