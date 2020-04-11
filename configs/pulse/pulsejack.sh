#!/bin/sh
# Run JACK daemon if not running and start PulseAudio as a JACK pipe.

if [ ! "$(ps -e | grep jackd)" ]
then
    jackd -T -dalsa -r44100 -p256 -P hw:M4 -C hw:M4 &
    sleep 1
    echo
fi
echo "Press Ctrl-C to stop PulseAudio."
pulseaudio -n -F /etc/pulse/jackpipe.pa
