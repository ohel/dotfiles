#/bin/sh
# Toggle display mirroring using xrandr. Looks for the second listed output in xrandr and uses Full HD resolution.

testfile=/tmp/switch_display
primary_display="eDP1"
primary_mode="1920x1080"
secondary_display=$(xrandr | grep " connected" | cut -f 1 -d ' ' | tail -n 1)
mode=$(xrandr | grep -A 1 $secondary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')
if [ -f $testfile ]
then
    xrandr --output $primary_display --mode "$primary_mode" --noprimary
    xrandr --output $secondary_display --mode "$primary_mode"
    rm $testfile
elif test "X$mode" != "X"
then
    xrandr --output $primary_display --mode "$primary_mode" --primary
    xrandr --output $secondary_display --off
    touch $testfile
fi

feh --bg-fill /opt/misc/pics/koli.jpg &
