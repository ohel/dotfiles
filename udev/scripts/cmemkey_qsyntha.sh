#!/bin/bash
# Connect CME M-Key MIDI keyboard to FluidSynth using ALSA. Use GUI (qsynth).

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0.0

if test "empty$(ps aux | grep qsynth | grep -v sh | grep -v grep)" == "empty"
 then /opt/programs/qsynth/bin/qsynth -a alsa &
 iter=0
 while test "empty$(ps aux | grep qsynth | grep -v grep)" == "empty"
 do
  sleep 0.5
  iter=`expr $iter + 1`
  if [ $iter -gt 5 ]
   then exit
  fi
 done
fi

output=$(aconnect -o | grep FLUID | cut -f 2 -d ' ' | tr -d -C [:digit:])
if test "empty$output" == "empty"
then
 iter=0
 while test "empty$output" == "empty"
 do
  sleep 0.5
  output=$(aconnect -o | grep FLUID | cut -f 2 -d ' ' | tr -d -C [:digit:])
  iter=`expr $iter + 1`
  if [ $iter -gt 10 ]
   then exit
  fi
 done
fi

input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
if test "empty$input" == "empty"
then
 iter=0
 while test "empty$input" == "empty"
 do
  sleep 0.5
  input=$(aconnect -i | grep CME | cut -f 2 -d ' ' | tr -d -C [:digit:])
  iter=`expr $iter + 1`
  if [ $iter -gt 10 ]
   then exit
  fi
 done
fi
aconnect $input:0 $output:0

