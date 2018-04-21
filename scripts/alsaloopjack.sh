#!/bin/bash
# Connect JACK to an ALSA loopback device.

alsa_in -j "ALSA output" -d loop_playback_out &
alsa_out -j "ALSA input" -d loop_record_in &
echo "ALSA/JACK bridge is active."
echo "Wait some time to reach absolute resample-rate stability."
wait
