#!/bin/sh
# Toggles external display using xrandr.
# Primary display is assumed to be the first one connected listed in xrandr output, or may be given as input parameter $2.
# External display is assumed to be the second one connected.
# For both displays, maximum resolution listed by xrandr is used.
# Useful on laptops with varying secondary displays.

# An operating mode for the script may be given as parameter $1:
# switch = switch the display between primary and secondary (default mode if parameter not given)
# extend = extend to the other display (assumes it's on the right side)
# mirror = mirror the display (in primary display resolution)

script_mode=${1:-"switch"}
primary_background=~/.themes/background
secondary_background=~/.themes/background2

primary_display=${2:-$(xrandr | grep " connected" | cut -f 1 -d ' ' | head -n 1)}
primary_mode=$(xrandr | grep -A 1 $primary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')

testfile=/tmp/switch_display

secondary_display=$(xrandr | grep " connected" | cut -f 1 -d ' ' | grep -v $primary_display | head -n 1)
secondary_mode=$(xrandr | grep -A 1 $secondary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')

panelwin="xfce4-panel"
panelheight=$(xwininfo -id $(wmctrl -l | grep $panelwin | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
panel_y=$(echo $(echo $primary_mode | cut -f 2 -d 'x') - $panelheight | bc)

if [ -f $testfile ]
then
    echo "Switching off external display."
    xrandr --output $primary_display --mode "$primary_mode" --primary
    xrandr --output $secondary_display --off
    rm $testfile
elif test "X$secondary_mode" != "X"
then
    if test "$script_mode" = "switch"
    then
        echo "Switching to external display."
        xrandr --output $secondary_display --mode "$secondary_mode" --primary
        xrandr --output $primary_display --off
        secondary_background=""
    elif test "$script_mode" = "extend"
    then
        echo "Extending to external display."
        xrandr --output $primary_display --mode "$primary_mode" --primary
        xrandr --output $secondary_display --mode "$secondary_mode" --right-of $primary_display
        wmctrl -r $panelwin -e 0,$panel_y,0,-1,-1
    elif test "$script_mode" = "mirror"
    then
        echo "Mirroring to external display."
        xrandr --output $primary_display --mode "$primary_mode" --noprimary
        xrandr --output $secondary_display --mode "$primary_mode"
        secondary_background=""
    fi
    touch $testfile
fi

feh --bg-fill --no-fehbg $primary_background $secondary_background
