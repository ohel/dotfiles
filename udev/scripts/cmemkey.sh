#!/usr/bin/sh
# Connect CME M-Key MIDI keyboard to FluidSynth using ALSA or JACK.
# Give "jack" or "cli" as $1 or $2. Defaults to ALSA with GUI (qsynth).
# In CLI and if jackd is already running, JACK is always used.

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0
audiocard=m4_hw

use_cli=""
use_jack=""
[ "$1" = "cli" ] || [ "$2" = "cli" ] && use_cli=1
[ "$1" = "jack" ] || [ "$2" = "jack" ] && use_jack=1

[ "$use_cli" ] || [ "$(ps -e | grep jackd)" ] && use_jack=1

if [ "$use_jack" ] && [ ! "$(ps -e | grep jackd)" ]
then
    jackd -T -t 1000 -dalsa -r44100 -p32 -n4 -P$audiocard &
    counter=0
    while [ ! "$(ps -e | grep jackd)" ]
    do
        sleep 0.5 || sleep 1
        counter=$(expr $counter + 1)
        [ $counter -gt 5 ] && exit 1
    done
fi
sleep 0.5 || sleep 1

if [ "$use_cli" ] && [ ! "$(ps -e | grep fluidsynth)" ]
then
    xfce4-terminal -x fluidsynth -a jack -c 2 -C 0 -g 0.5 -G 1 -j -m alsa_seq -p FLUID -r 44100 -R 0 -z 128 -f $HOME/.config/fluidsynth_config &
    counter=0
    while [ ! "$(ps -e | grep fluidsynth)" ]
    do
        sleep 0.5 || sleep 1
        counter=$(expr $counter + 1)
        [ $counter -gt 5 ] && exit 1
    done
fi

if [ ! "$use_cli" ] && [ ! "$(ps -e | grep qsynth)" ]
then
    qsynth_backend=alsa
    [ "$use_jack" ] && qsynth_backend=jack
    setsid qsynth -a $qsynth_backend &
    counter=0
    while [ ! "$(ps -e | grep qsynth)" ]
    do
        sleep 0.5 || sleep 1
        counter=$(expr $counter + 1)
        [ $counter -gt 5 ] && exit 1
    done
fi

output=$(aconnect -o | grep FLUID | cut -f 2 -d ' ' | tr -d -C [:digit:])
if [ ! "$output" ]
then
    counter=0
    while [ ! "$output" ]
    do
        sleep 0.5 || sleep 1
        output=$(aconnect -o | grep FLUID | cut -f 2 -d ' ' | tr -d -C [:digit:])
        counter=$(expr $counter + 1)
        [ $counter -gt 10 ] && exit 1
    done
fi

input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
if [ ! "$input" ]
then
    counter=0
    while [ ! "$input" ]
    do
        sleep 0.5 || sleep 1
        input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
        counter=$(expr $counter + 1)
        [ $counter -gt 10 ] && exit 1
    done
fi

echo $input $output
aconnect $input:0 $output:0
