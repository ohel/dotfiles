#!/usr/bin/sh
# Connect ALSA loopback devices to default audio output and input devices.

buffer_size=2048

# Playback
arecord -r 44100 -c 2 -f S16_LE -D loop_vm_dac_out --buffer-size=$buffer_size | aplay --buffer-size=$buffer_size &

# Record
arecord -r 44100 -c 2 -f S16_LE --buffer-size=$buffer_size | aplay -D loop_vm_adc_in --buffer-size=$buffer_size
