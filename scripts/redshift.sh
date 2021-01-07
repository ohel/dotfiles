#!/bin/sh
# Change screen color temperature using the redshift tool.
# Give a temperature delta in $1, e.g. -500.
# If $1 = r, reset adjustments.
# If $2 = b, also change brightness. This is done using the backlight script (if backlight is module present), otherwise using redshift.
# If no parameters are given, uses a simple custom algorithm to automatically guess good values.

tempfile=~/.cache/redshift_temp
max=6500
min=3500
[ "$1" = "r" ] && redshift -x && exit 0
set_brightness=""
[ "$1" = "b" ] && set_brightness=1
[ "$2" = "b" ] && set_brightness=1

if [ "$#" -gt 0 ] && [ "$(echo "$1" | grep "^[-+0-9]*$")" ]
then
    [ ! -e $tempfile ] && echo $max > $tempfile
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
    echo $new > $tempfile
    notify_time=300
else
    # Make it so that from 8pm to 2am the brightness drops from 1.0 to 0.5.
    # Compensate for winter months making the shift earlier.
    month=$(date +%m)
    compensation=0
    [ $month -gt 10 ] && compensation=3
    [ $month -gt 11 ] && compensation=4
    [ $month -lt 2 ] && compensation=4
    [ $month -lt 3 ] && compensation=3
    hourval=$(expr $(date +%H) + $compensation)
    [ $hourval -lt 8 ] && hourval=26
    [ $hourval -gt 26 ] && hourval=26
    hourval=$(expr $hourval - 20)
    [ $hourval -lt 0 ] && hourval=0
    hourval=$(expr 12 - $hourval)
    set_brightness=1
    delta=$(expr $max - $min)
    new=$(echo "scale=2; $min + $hourval / 12 * $delta" | bc | cut -f 1 -d '.')
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
    $scriptsdir/backlight.sh $brightness || b="-b $brightness"
fi

redshift $resetparam -O $new $b 2>&1 > /dev/null
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "New redshift value: $new" -t $notify_time
