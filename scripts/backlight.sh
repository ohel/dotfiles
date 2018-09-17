#!/bin/sh
# Change laptop screen backlight brightness via script.
# Give a brightness delta integer (positive or negative prefixed with -) as parameter.

backlight=/sys/class/backlight/intel_backlight

[ "$#" -eq 0 ] && exit 1

max=$(cat $backlight/max_brightness);
current=$(cat $backlight/brightness);

new=$(echo $current + $1 | bc)
if [ $new -gt $max ]
then
    new=$max
elif [ $new -lt 1 ]
then
    new=1
fi

echo $new > $backlight/brightness
