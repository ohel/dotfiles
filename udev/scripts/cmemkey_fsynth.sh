#!/bin/bash
# Connect CME M-Key MIDI keyboard to FluidSynth using JACK. No GUI.
# Use realtime processing if possible.

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0.0
audiocard=julia_analog_hw

if [ "$(ps -e | grep jackd)" == "" ]
then
    if [ "$(uname -r | grep rt)" != "" ]
        then jackd -P 70 -R -T -t 1000 -dalsa -r44100 -p32 -n2 -P$audiocard -o2 &
    else
        jackd -R -T -t 1000 -dalsa -r44100 -p128 -n2 -P$audiocard -o2 &
    fi
    counter=0
    while [ "$(ps -e | grep jackd)" == "" ]
    do
        sleep 0.5
        counter=$(expr $counter + 1)
        [ $counter -gt 5 ] && exit 1
    done
fi
sleep 0.5

if [ "$(ps -e | grep fluidsynth)" == "" ]
then
    xfce4-terminal -x fluidsynth -a jack -c 2 -C 0 -g 0.5 -G 1 -j -m alsa_seq -p FluidSynth -r 44100 -R 0 -z 128 -f $HOME/.config/fluidsynth_config &
    counter=0
    while [ "$(ps -e | grep fluidsynth)" == "" ]
    do
        sleep 0.5
        counter=$(expr $counter + 1)
        [ $counter -gt 5 ] && exit 1
    done
fi

output=$(aconnect -o | grep FluidSynth | cut -f 2 -d ' ' | tr -d -C [:digit:])
if [ "$output" == "" ]
then
    counter=0
    while [ "$output" == "" ]
    do
        sleep 0.5
        output=$(aconnect -o | grep FluidSynth | cut -f 2 -d ' ' | tr -d -C [:digit:])
        counter=$(expr $counter + 1)
        [ $counter -gt 10 ] && exit 1
    done
fi

input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
if [ "$input" == "" ]
then
    counter=0
    while [ "$input" == "" ]
    do
        sleep 0.5
        input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
        counter=$(expr $counter + 1)
        [ $counter -gt 10 ] && exit 1
    done
fi
aconnect $input:0 $output:0
