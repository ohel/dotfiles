#!/bin/sh
# Run JACK daemon if not running and start PulseAudio as a JACK pipe.

device="hw:M4"

if [ ! "$(ps -e | grep jackd)" ]
then
    jackd -T -dalsa -r44100 -p256 -P $device -C $device &
    sleep 1
    echo
fi

echo "Press Ctrl-C to stop PulseAudio."
echo
echo "You may see errors such as \"jack_set_property() failed\" but they are not fatal."
pulseaudio -n -F /etc/pulse/jackpipe.pa --exit-idle-time=-1
