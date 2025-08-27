#!/usr/bin/sh
# Change screen color temperature using the redshift tool.
# Give a temperature delta in $1, e.g. -500.
# If $1 or $2 = r, reset adjustments.
# If $1 or $2 = b, also change brightness. This is done using a backlight control script (if backlight exists), otherwise using redshift.
# If no parameters are given, uses a simple custom algorithm to automatically guess good values.
# To make adjusting automatic, use this script in a user's crontab (crontab -e -u user) for example like this:
# 0,30 * * * * DISPLAY=:0.0 /home/user/.scripts/redshift.sh

cachedir=~/.cache
scriptsdir=$(dirname "$(readlink -f "$0")")
tempfile=$cachedir/redshift_temp
max=6500
min=4000
set_brightness=""
[ "$1" = "b" ] && set_brightness=1
[ "$2" = "b" ] && set_brightness=1

[ ! -d $cachedir ] || [ ! "$(xhost 2>/dev/null)" ] && exit 1

[ ! -e $tempfile ] && echo $max > $tempfile 2>/dev/null
current=$(cat $tempfile)
[ ! "$current" ] && current=$max

if [ "$1" = "r" ] || [ "$2" = "r" ]
then
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Reset redshift" -t 1000
    redshift -x
    ([ "$1" = "b" ] || [ "$2" = "b" ]) && $scriptsdir/backlight.sh 0.50
    [ -e $tempfile ] && echo $max > $tempfile
    exit 0
fi

if [ "$#" -gt 0 ] && echo "$1" | grep -q "^[-+0-9]*$"
then
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
    [ $month -gt 10 ] && compensation=2
    [ $month -gt 11 ] && compensation=3
    [ $month -lt 3 ] && compensation=2
    [ $month -lt 2 ] && compensation=3
    hourval=$(expr $(date +%H) + $compensation)
    [ $hourval -lt 8 ] && hourval=26
    [ $hourval -gt 26 ] && hourval=26
    hourval=$(expr $hourval - 20)
    [ $hourval -lt 0 ] && hourval=0
    factor=$(expr 6 - $hourval)
    set_brightness=1
    delta=$(expr $max - $min)
    new=$(echo "scale=2; $min + $factor/6 * $delta" | bc | cut -f 1 -d '.')
    notify_time=3000
fi

[ -e $tempfile ] && echo $new > $tempfile
# Don't do anything if new value would be the same as old one.
[ $new -eq $current ] && exit 0

# The -P reset parameter was introduced in redshift 1.12.
version=$(redshift -V | cut -f 2 -d ' ' | tr -d '.')
[ $version -gt 111 ] && resetparam="-P"

b=""
if [ "$set_brightness" ]
then
    brightness=$(echo "scale=2; $new/$max" | bc)
    # Script will succeed if hardware backlight can be used, fail otherwise - in which case use the -b parameter for redshift.
    # Use a much dimmer value for hardware backlights.
    $scriptsdir/backlight.sh $(echo "scale=2; $brightness * $brightness * $brightness * 0.75" | bc) || b="-b $brightness"
fi

redshift $resetparam -O $new $b 2>&1 > /dev/null
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "New redshift value: $new" -t $notify_time
