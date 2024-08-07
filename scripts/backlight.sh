#!/usr/bin/sh
# Change laptop screen backlight brightness via script.
# Give a brightness delta integer (positive or negative prefixed with -) as parameter.
# If parameter is not an integer (has a .), it is interpreted as a percentage of max brightness.

backlight=$(ls /sys/class/backlight/ | head -n 1)

[ ! "$backlight" ] && echo "No backlight control found." && exit 1
[ "$#" -eq 0 ] && exit 1

backlight="/sys/class/backlight/$backlight"

max=$(cat $backlight/max_brightness)
current=$(cat $backlight/brightness)

if [ "$(echo "$1" | grep \\.)" ]
then
    new=$(echo "$1 * $max" | bc | cut -f 1 -d '.')
else
    new=$(echo $current + $1 | bc)
    if [ $new -gt $max ]
    then
        new=$max
    elif [ $new -lt 1 ]
    then
        new=1
    fi
fi

echo $new > $backlight/brightness
