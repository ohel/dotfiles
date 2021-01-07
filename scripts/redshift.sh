#!/bin/sh
# Change screen color temperature using the redshift tool.
# Give a temperature delta in $1, e.g. -500.
# If $1 = r, reset adjustments.
# If $2 = b, also change brightness. This is done using the backlight script (if backlight is module present), otherwise using redshift.
# If no parameters are given, uses a simple custom algorithm to automatically guess good values.

tempfile=~/.cache/redshift_temp
max=6500
min=4000
[ "$1" = "r" ] && redshift -x && exit 0
set_brightness=""
[ "$1" = "b" ] && set_brightness=1
[ "$2" = "b" ] && set_brightness=1

[ ! -e $tempfile ] && echo $max > $tempfile

if [ "$#" -gt 0 ] && [ "$(echo "$1" | grep "^[-+0-9]*$")" ]
then
    current=$(cat $tempfile);
    [ ! "$current" ] && current=$max

    delta=$(echo "$1" | tr -d '+')
    new=$(echo $current + $delta | bc)
    if [ $new -gt $max ]
    then
        new=$max
    elif [ $new -lt $min ]
    then
        new=$min
    fi
    notify_time=300
else
    # Make it so that the brightness drops from 8pm to 2am.
    # Compensate for winter months making the shift earlier.
    month=$(date +%m)
    compensation=0
    [ $month -gt 10 ] && compensation=3
    [ $month -gt 11 ] && compensation=4
    [ $month -lt 3 ] && compensation=3
    [ $month -lt 2 ] && compensation=4
    hourval=$(expr $(date +%H) + $compensation)
    [ $hourval -lt 8 ] && hourval=26
    [ $hourval -gt 26 ] && hourval=26
    hourval=$(expr $hourval - 20)
    [ $hourval -lt 0 ] && hourval=0
    hourval=$(expr 6 - $hourval)
    set_brightness=1
    delta=$(expr $max - $min)
    new=$(echo "scale=2; $min + $hourval / 6 * $delta" | bc | cut -f 1 -d '.')
    notify_time=3000

    # Don't do anything automatically if new value would be the maximum.
    [ $new -eq $max ] && exit 0
fi

# The -P reset parameter was introduced in redshift 1.12.
version=$(redshift -V | cut -f 2 -d ' ' | tr -d '.')
[ $version -gt 111 ] && resetparam="-P"

b=""
if [ "$set_brightness" ]
then
    scriptsdir=$(dirname "$(readlink -f "$0")")
    brightness=$(echo "scale=2; $new / $max" | bc)
    # Script will succeed if hardware backlight can be used, will fail otherwise.
    # Use a bit dimmer value for hardware backlights.
    $scriptsdir/backlight.sh $(echo "scale=2; $brightness * 0.75" | bc) || b="-b $brightness"
fi

echo $new > $tempfile
redshift $resetparam -O $new $b 2>&1 > /dev/null
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "New redshift value: $new" -t $notify_time
