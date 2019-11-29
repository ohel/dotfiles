#!/bin/sh
# Start and connect basic stuff to begin practicing with Alesis Turbo edrums.

QJACK_PRESET=Julia_44100Hz_stereo

scriptdir=$(dirname "$(readlink -f "$0")")

qjackctl -p $QJACK_PRESET -s &
pid_qjackctrl=$!
sleep 1

hydrogen -s $scriptdir/drum_practice.h2song &
pid_hydrogen=$!
sleep 1

# mididings_script is originally named mididings, but there's a directory by the same name for Python code if installing like I did, i.e. manually to an arbitrary location
/opt/programs/mididings/mididings_script -f $scriptdir/alesis_turbo.py &
pid_mididings=$!
sleep 1

echo "Connecting MIDI"
aconnect "Alesis Turbo" mididings
aconnect mididings:1 Hydrogen
echo "Connecting ALSA/JACK bridge"
alsa_in -j "ALSA output" -d loop_playback_out &
alsa_out -j "ALSA input" -d loop_record_in &
sleep 1
jack_connect "ALSA output:capture_1" system:playback_1
jack_connect "ALSA output:capture_2" system:playback_2

echo
echo Press return twice to quit.
read temp
echo Press return once to quit.
read temp

kill $pid_mididings
kill $pid_hydrogen
kill $pid_qjackctrl
killall jackd
