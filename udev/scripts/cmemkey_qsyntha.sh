#!/bin/sh
# Connect CME M-Key MIDI keyboard to FluidSynth using ALSA. Use GUI (qsynth).

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0.0

if [ ! "$(ps -e | grep qsynth)" ]
then
    setsid qsynth -a alsa
    timer=0
    while [ ! "$(ps -e | grep qsynth)" ]
    do
        sleep 0.5 || sleep 1
        timer=$(expr $timer + 1)
        [ $timer -gt 5 ] && exit 1
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
aconnect $input:0 $output:0
