#!/bin/bash
# Without PulseAudio one must use BlueALSA to connect to Bluetooth headsets.
# Unfortunately, there's no way of using a dmix device with bluealsa directly,
# as ALSA will just give an error message if dmix has bluealsa as slave.
# As of BlueALSA version 1.3.0, some applications refuse to play anything at
# all into a bluealsa device unless LIBASOUND_THREAD_SAFE=0 is set.
# JACK server however plays with a bluealsa device nicely.

# By using an ALSA loopback device we can mix audio streams.
# The other end of the loopback device must be connected somewhere.
# This script has two modes, one using JACK and the other using a pipe.

# If $1 == "jack", a JACK server using a BlueALSA device as output
# is started and the loopback device is connected to it.
# If $1 is something else or empty, audio is routed using arecord and aplay.

# Finally a new bash shell is started, with the loopback device as
# the default audio device. The shell is not started if $2 is given.

# If $2 is given, killall $2 start it with the new ALSA environment variables.
# A good candidate would be for example xfce4-panel, so that whatever one starts
# via the panel, they will default to using the Bluetooth audio device.

mode=${1:-alsa}
bt_env_program=$2

loop_in=loop_playback_in_mix
loop_out=loop_playback_out
loop_ctl=loop
bt_audio=bluetooth
# Overruns may occur and CPU usage increase with too small a number.
buffer_size=512

tmp_bashrc=/dev/shm/bluealsabashrc

scriptsdir=$(dirname "$(readlink -f "$0")")

if ! $scriptsdir/bt_audio_connect.sh;
then
    echo "Bluetooth audio is not connected. Exiting."
    sleep 1
    exit 1
fi

if [ "$mode" == "jack" ]
then
    /usr/bin/jackd -r -p128 -dalsa -d$bt_audio -r44100 -p512 -n2 -s -S -P -o2 >/dev/null &
    echo -n "Waiting for jackd to start 3..."
    tput cub 4 && sleep 1
    echo -n "2"
    tput cub 1 && sleep 1
    echo -n "1"
    tput cub 1 && sleep 1
    tput cuf 4 && echo

    # This is a hack to trick alsa_in below into using a correct format.
    # If audio is playing when starting alsa_in, audio will work after that, too.
    # If audio is not playing when you start alsa_in, ALSA gives a format error.
    echo "Run speaker-test hack..."
    speaker-test -D $loop_in -r 44100 -X -f 1 -t sine -l 1 &>/dev/null &
    sleep 1
    alsa_in -j "Loop out" -d $loop_out &>/dev/null &
    echo "Waiting for alsa_in to start..."
    sleep 1

    jack_connect "Loop out:capture_1" "system:playback_1" &>/dev/null
    jack_connect "Loop out:capture_2" "system:playback_2" &>/dev/null
else
    arecord -f cd --buffer-size $buffer_size -D $loop_out | env LIBASOUND_THREAD_SAFE=0 aplay --buffer-size $buffer_size -D $bt_audio &
    pid=$!
fi

if ! [ "$bt_env_program" ]
then
    cat > $tmp_bashrc << EOF
    export ALSA_DEFAULT_PCM=$loop_in
    export ALSA_DEFAULT_CTL=$loop_ctl
    PROMPT_COMMAND='echo -ne "\e]0;ALSA loop\007"'
    PS1='\[\e[0;37m\]\w \[\e[1;36m\]ALSA loop \[\e[1;30m\]\$\[\e[0m\] '
    cd
    echo -ne '\e[8;8;50t'
    echo "ALSA defaults in this shell are:"
    echo
    echo "    ALSA_DEFAULT_PCM=$loop_in"
    echo "    ALSA_DEFAULT_CTL=$loop_ctl"
    echo
    echo "On exit, Bluetooth audio is killed."
    echo
EOF
    clear
    bash --rcfile $tmp_bashrc
else
    killall $bt_env_program
    sleep 1
    env ALSA_DEFAULT_PCM=$loop_in ALSA_DEFAULT_CTL=$loop_ctl $bt_env_program &>/dev/null &
    clear
    echo -ne '\e[8;7;50t'
    echo "Started $bt_env_program in an environment where:"
    echo
    echo "    ALSA_DEFAULT_PCM=$loop_in"
    echo "    ALSA_DEFAULT_CTL=$loop_ctl"
    echo
    echo "Press return to exit."
    read
fi

if [ "$mode" == "jack" ]
then
    killall alsa_in &>/dev/null
    killall jackd &>/dev/null
else
    kill $pid &>/dev/null
fi
