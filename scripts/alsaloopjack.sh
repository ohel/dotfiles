#!/bin/bash
# Connect JACK to an alsa loopback device (ends are named loop_in_jack, loop_out_jack).

echo "ALSA/JACK bridge is active."
alsa_in -j "ALSA output" -dloop_out_jack &
alsa_out -j "ALSA input" -dloop_in_jack &
alsa_in -j "ALSA output 2" -dloop2_out_jack &
alsa_out -j "ALSA input 2" -dloop2_in_jack 

