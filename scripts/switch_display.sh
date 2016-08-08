#/bin/sh
# Toggles external display using xrandr. Looks for the second listed output in xrandr and uses its maximum resolution.
# Useful on laptops with varying secondary displays.

# An operating mode for the script may be given as parameter:
# switch = switch the display between primary and secondary (default mode if parameter not given)
# extend = extend to the other display (assumes it's on the right side)
# mirror = mirror the display (in primary display resolution)

primary_display="eDP1"
primary_mode="1920x1080"

testfile=/tmp/switch_display
script_mode=${1:-"switch"}

secondary_display=$(xrandr | grep " connected" | cut -f 1 -d ' ' | tail -n 1)
secondary_mode=$(xrandr | grep -A 1 $secondary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')

if [ -f $testfile ]
then
    xrandr --output $primary_display --mode "$primary_mode" --primary
    xrandr --output $secondary_display --off
    rm $testfile
elif test "X$secondary_mode" != "X"
then
    if test "$script_mode" == "switch"
    then
        xrandr --output $secondary_display --mode "$secondary_mode" --primary
        xrandr --output $primary_display --off
    elif test "$script_mode" == "extend"
    then
        xrandr --output $primary_display --mode "$primary_mode" --primary
        xrandr --output $secondary_display --mode "$secondary_mode" --right-of $primary_display
    elif test "$script_mode" == "mirror"
    then
        xrandr --output $primary_display --mode "$primary_mode" --noprimary
        xrandr --output $secondary_display --mode "$primary_mode"
    fi
    touch $testfile
fi

feh --bg-fill /opt/misc/pics/koli.jpg &
