#!/bin/bash
# Start a JACK server using a bluealsa device as output.

scriptsdir=$(dirname "$(readlink -f "$0")")
$scriptsdir/bluealsa.sh

killall jackd
killall alsa_in

export ALSA_DEFAULT_PCM=loop_playback_in_mix

/usr/bin/jackd -r -p512 -dalsa -dbluetooth -r44100 -p512 -n2 -s -S -P -o2 &
echo "Waiting for jackd to start 3..."
sleep 1
echo "Waiting for jackd to start 2..."
sleep 1
echo "Waiting for jackd to start 1..."
sleep 1

# This is a hack to trick alsa_in below into using a correct format.
# If audio is playing when starting alsa_in, audio will work after that, too.
# If audio is not playing when you start alsa_in, ALSA gives a format error.
echo "Run speaker-test hack..."
speaker-test -r 44100 -X -f 1 -t sine -l 1 &>/dev/null &
sleep 1
alsa_in -j "Loop out" -dloop_playback_out &
echo "Waiting for alsa_in to start..."
sleep 1

jack_connect "Loop out:capture_1" "system:playback_1"
jack_connect "Loop out:capture_2" "system:playback_2"

clear
echo "Use the following prefix for commands to use the audio:"
echo "env ALSA_DEFAULT_PCM=loop_playback_in_mix ALSA_DEFAULT_CTL=loop "
echo
echo "Press return to kill jackd."
read
killall alsa_in
killall jackd
