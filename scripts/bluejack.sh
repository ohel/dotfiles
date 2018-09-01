#!/bin/bash
# Without PulseAudio one must use BlueALSA to connect to Bluetooth headsets.
# Unfortunately, there's no way of using a dmix device with bluealsa directly,
# and some applications simply refuse to play anything at all into a bluealsa device.
# JACK server however plays with a bluealsa device nicely.

# The script starts a JACK server using the BlueALSA device 'bluetooth' as output and
# connects the ALSA loopback device 'loop_playback_out' to it.
# Finally a new bash shell is started, with the other end of the loopback device
# as the default audio device. The shell is not started if $1 is given.

# If $1 is given, killall $1 start it with the new ALSA environment variables.
# A good candidate would be for example xfce4-panel, so that whatever one starts
# via the panel, they will default to using the Bluetooth audio device.

bt_env_program=$1
tmp_bashrc=/dev/shm/bluejackbashrc
scriptsdir=$(dirname "$(readlink -f "$0")")
if ! $scriptsdir/bluealsa.sh;
then
    echo "BlueALSA is not connected. Exiting."
    sleep 1
    exit 1
fi

killall alsa_in &>/dev/null
killall jackd &>/dev/null

/usr/bin/jackd -r -p128 -dalsa -dbluetooth -r44100 -p512 -n2 -s -S -P -o2 >/dev/null &
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
speaker-test -D loop_playback_in_mix -r 44100 -X -f 1 -t sine -l 1 &>/dev/null &
sleep 1
alsa_in -j "Loop out" -d loop_playback_out &>/dev/null &
echo "Waiting for alsa_in to start..."
sleep 1

jack_connect "Loop out:capture_1" "system:playback_1" &>/dev/null
jack_connect "Loop out:capture_2" "system:playback_2" &>/dev/null

if [ "$bt_env_program" = "" ]
then
    cat > $tmp_bashrc << EOF
    export ALSA_DEFAULT_PCM=loop_playback_in_mix
    export ALSA_DEFAULT_CTL=loop
    PROMPT_COMMAND='echo -ne "\e]0;ALSA loop\007"'
    PS1='\[\e[0;37m\]\w \[\e[1;36m\]ALSA loop \[\e[1;30m\]\$\[\e[0m\] '
    cd
    echo -ne '\e[8;7;50t'
    echo "Default ALSA device in this shell is:"
    echo
    echo "   loop_playback_in_mix"
    echo
    echo "On exit, jackd will be killed."
    echo
EOF
    clear
    bash --rcfile $tmp_bashrc
else
    killall $bt_env_program
    sleep 1
    env ALSA_DEFAULT_PCM=loop_playback_in_mix ALSA_DEFAULT_CTL=loop $bt_env_program &>/dev/null &
    clear
    echo "Started $bt_env_program in environment where:"
    echo
    echo     ALSA_DEFAULT_PCM=loop_playback_in_mix
    echo     ALSA_DEFAULT_CTL=loop
    echo
    echo "Press return to exit and kill jackd."
    read
fi

killall alsa_in &>/dev/null
killall jackd &>/dev/null
