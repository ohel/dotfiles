#!/bin/bash
# Toggles external display using xrandr.
# Primary display is assumed to be the first one connected listed in xrandr output, or may be given as input parameter $2.
# External display is assumed to be the second one connected.
# For both displays, maximum resolution listed by xrandr is used.
# Useful on laptops with varying secondary displays.

# An operating mode for the script may be given as parameter $1:
# switch = switch the display between primary and secondary (default mode if parameter not given)
# extend = extend to the other display (xrandr position may be given in $3, defaults to "right-of")
# mirror = mirror the display (in primary display resolution)

script_mode=${1:-"switch"}
primary_background=~/.themes/background
secondary_background=~/.themes/background2

primary_display=${2:-$(xrandr | grep " connected" | cut -f 1 -d ' ' | head -n 1)}
primary_mode=$(xrandr | grep -A 1 $primary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')
echo "Primary display: $primary_display with mode $primary_mode."

testfile=/tmp/external_display

secondary_display=$(xrandr | grep " connected" | cut -f 1 -d ' ' | grep -v $primary_display | head -n 1)
[ "$secondary_display" != "" ] && secondary_mode=$(xrandr | grep -A 1 $secondary_display | tail -n 1 | tr -s ' ' | cut -f 2 -d ' ')

if [ -f $testfile ]
then
    echo "Switching off external display $secondary_display."
    xrandr --output $primary_display --mode $primary_mode --primary
    xrandr --output $secondary_display --off
    secondary_background=""
    rm $testfile
elif [ "$secondary_mode" != "" ]
then
    if [ "$script_mode" == "switch" ]
    then
        echo "Switching to external display $secondary_display."
        xrandr --output $secondary_display --mode $secondary_mode --primary
        xrandr --output $primary_display --off
        secondary_background=""
    elif [ "$script_mode" == "extend" ]
    then
        echo "Extending to external display $secondary_display."
        xrandr --output $primary_display --mode $primary_mode --primary
        position=${3:-"right-of"}
        xrandr --output $secondary_display --mode $secondary_mode --$position $primary_display
        panelwin="xfce4-panel"
        panelheight=$(xwininfo -id $(wmctrl -l | grep $panelwin | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
        panel_y=$(echo $(echo $primary_mode | cut -f 2 -d 'x') - $panelheight | bc)
        wmctrl -r $panelwin -e 0,$panel_y,0,-1,-1
    elif [ "$script_mode" == "mirror" ]
    then
        echo "Mirroring to external display $secondary_display."
        p_width=$(echo $primary_mode | cut -f 1 -d 'x')
        p_height=$(echo $primary_mode | cut -f 2 -d 'x')
        s_width=$(echo $secondary_mode | cut -f 1 -d 'x')
        s_height=$(echo $secondary_mode | cut -f 2 -d 'x')
        mirror_width=$p_width
        mirror_height=$p_height
        [ $s_width -lt $p_width ] && mirror_width=$s_width
        [ $s_height -lt $p_height ] && mirror_height=$s_height
        mirror_mode=$mirror_width"x"$mirror_height
        xrandr --output $primary_display --mode $mirror_mode --noprimary
        xrandr --output $secondary_display --mode $mirror_mode
        secondary_background=""
        echo "Set mode $mirror_mode."
    fi
    touch $testfile
fi

which feh &>/dev/null && feh --bg-fill --no-fehbg $primary_background $secondary_background 2>/dev/null
