#!/bin/sh
# Start and connect basic stuff to begin practicing with Alesis Turbo edrums.

scriptdir=$(dirname "$(readlink -f "$0")")
qjackctl -p Julia_44100Hz_stereo -s &
sleep 1
hydrogen -s $scriptdir/drum_practice.h2song &
sleep 1
# mididings_script is originally named mididings, but there's a directory by the same name for Python code
/opt/programs/mididings/mididings_script -f $scriptdir/alesis_turbo.py &
sleep 1
aconnect "Alesis Turbo" mididings
aconnect mididings:1 Hydrogen
wait
