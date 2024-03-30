#!/usr/bin/sh
# Connect JACK to an ALSA loopback device.

alsa_in -j "ALSA output" -d loop_playback_out &
alsa_out -j "ALSA input" -d loop_record_in &
sleep 1
jack_connect "ALSA output:capture_1" "system:playback_1"
jack_connect "ALSA output:capture_2" "system:playback_2"
echo "ALSA/JACK bridge is active."
echo "Wait some time to reach absolute resample-rate stability."
wait
