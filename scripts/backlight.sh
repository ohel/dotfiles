#!/bin/bash
backlight=/sys/class/backlight/intel_backlight
max=$(cat $backlight/max_brightness);
current=$(cat $backlight/brightness);
if [ "$#" -eq 0 ]
then
    exit
fi

new=$(echo $current + $1 | bc)
if [ $new -gt $max ]
then
    new=$max
elif [ $new -lt 1 ]
then
    new=1
fi

echo $new > $backlight/brightness
