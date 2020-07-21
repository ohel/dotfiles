#!/bin/sh
# Toggles external display using xrandr.
# Primary display is assumed to be the first one connected listed in xrandr output, or may be given as input parameter $2.
# External display is assumed to be the second one connected.
# For both displays, maximum resolution listed by xrandr is used.
# Useful on laptops with varying secondary displays.

# An operating mode for the script may be given as parameter $1:
# switch = switch the display between primary and secondary (default mode if parameter not given)
# extend = extend to the other display (xrandr position may be given in $3, defaults to "right-of")
# mirror = mirror the display (using highest common resolution)

# If a secondary display is not found, the primary display is reset to its best resolution.

script_mode=${1:-"switch"}
primary_background=~/.themes/background
secondary_background=~/.themes/background2
testfile=/tmp/external_display
HIDPI_WIDTH=3840

primary_display=${2:-$(xrandr | grep " connected" | cut -f 1 -d ' ' | head -n 1)}

# Sometimes the native resolution is not the first mode line, but the second. This might be the case with e.g. 4K televisions.
primary_mode=$(xrandr | grep -A 1 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
primary_mode_candidate=$(xrandr | grep -A 2 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
[ $(echo $primary_mode | grep -o "^[0-9]\{3,4\}") -lt $(echo $primary_mode_candidate | grep -o "^[0-9]\{3,4\}") ] && primary_mode=$primary_mode_candidate

echo "Primary display: $primary_display with mode $primary_mode."
p_width=$(echo $primary_mode | cut -f 1 -d 'x')

secondary_display=$(xrandr | grep " connected" | cut -f 1 -d ' ' | grep -v $primary_display | head -n 1)
if [ "$secondary_display" ]
then
    echo "Found secondary display $secondary_display."
    secondary_mode=$(xrandr | grep -A 1 $secondary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
    s_width=$(echo $secondary_mode | cut -f 1 -d 'x')
fi

if [ -f $testfile ]
then
    echo "Switching off external display $secondary_display."
    xrandr --output $primary_display --mode $primary_mode --primary \
        --output $secondary_display --off
    secondary_background=""
    rm $testfile
elif [ ! "$secondary_mode" ]
then
    echo No secondary display found, resetting primary display.
    xrandr --output $primary_display --mode $primary_mode --primary
else
    if [ "$script_mode" = "switch" ]
    then
        echo "Switching to external display $secondary_display."
        xrandr --output $secondary_display --mode $secondary_mode --primary \
            --output $primary_display --off
        secondary_background=""
    elif [ "$script_mode" = "extend" ]
    then
        echo "Extending to external display $secondary_display."
        position=${3:-"right-of"}
        xrandr --output $primary_display --mode $primary_mode --primary \
            --output $secondary_display --mode $secondary_mode --$position $primary_display
        panelwin="xfce4-panel"
        panelheight=$(xwininfo -id $(wmctrl -l | grep $panelwin | cut -f 1 -d ' ') | grep Height | cut -f 2 -d ":" | tr -d -c [:digit:])
        panel_y=$(echo $(echo $primary_mode | cut -f 2 -d 'x') - $panelheight | bc)
        wmctrl -r $panelwin -e 0,$panel_y,0,-1,-1
    elif [ "$script_mode" = "mirror" ]
    then
        echo "Mirroring to external display $secondary_display."

        primary_modes=$(xrandr | grep -z -o "$primary_display.*[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n +2 | tr -s ' ' | cut -f 2 -d ' ')
        secondary_modes=$(xrandr | grep -z -o "$secondary_display.*[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n +2 | tr -s ' ' | cut -f 2 -d ' ')

        selected_mode=""
        for modeline in $primary_modes
        do
            if [ ! "$selected_mode" ]
            then
                for match in $secondary_modes
                do
                    if [ "$modeline" = "$match" ]
                    then
                        echo "Found common resolution $match."
                        selected_mode=$match
                        break
                    fi
                done
            fi
        done

        if [ ! "$selected_mode" ]
        then
            echo No common resolution found.
            exit 1
        fi

        mirror_width=$(echo $selected_mode | cut -f 1 -d 'x')
        mirror_height=$(echo $selected_mode | cut -f 2 -d 'x')
        mirror_mode=$mirror_width"x"$mirror_height
        xrandr --output $primary_display --mode $mirror_mode --noprimary \
            --output $secondary_display --mode $mirror_mode
        secondary_background=""
        echo "Set mode $mirror_mode."
    fi
    touch $testfile
fi

# Xrandr only shows the physical size if the display is connected, therefore we need to call xrandr again.
# Sometimes the size does not actually match real world. In that case, one can export DPI per-system in e.g. ~/.profile.env_extra
p_phys_width=$(xrandr | grep -A 1 $primary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$p_phys_width" ]
then
    p_dpi_calc=$(echo "scale=2; $p_width / $p_phys_width * 25.4" | bc | cut -f 1 -d '.')
    p_dpi_set=96
    [ $p_dpi_calc -gt 100 ] && p_dpi_set=112
    [ $p_dpi_calc -gt 140 ] && [ $p_phys_width -gt 300 ] && p_dpi_set=144
    [ "$DPI" ] && p_dpi_set=$DPI
    common_dpi=$p_dpi_set
fi

scale=1
[ $p_width -eq $HIDPI_WIDTH ] && scale=2

[ "$secondary_display" ] && s_phys_width=$(xrandr | grep -A 1 $secondary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$s_phys_width" ]
then
    s_phys_width=$(xrandr | grep -A 1 $secondary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
    s_dpi_calc=$(echo "scale=2; $s_width / $s_phys_width * 25.4" | bc | cut -f 1 -d '.')
    s_dpi_set=96
    [ $s_dpi_calc -gt 100 ] && s_dpi_set=106
    [ $s_dpi_calc -gt 140 ] && [ $s_phys_width -gt 300 ] && s_dpi_set=144
    [ $s_width -eq $HIDPI_WIDTH ] && scale=2
    (! [ "$common_dpi" ] || [ $s_dpi_set -lt $p_dpi_set ]) && common_dpi=$s_dpi_set
fi

# HiDPI (4K) displays need some magic. Not all applications (e.g. GTK2) support scaling, so double the DPI is required for them to look "normal".
# However, we only want this if GDK is set to scale down font sizes accordingly. Otherwise the window scaling factor should be used.
[ "$(env | grep GDK_DPI_SCALE=0.5)" ] && common_dpi=$(expr 2 \* $common_dpi)
echo Final DPI: $common_dpi

if [ $(which xfconf-query >/dev/null 2>&1) ]
then
    xfconf-query -c xsettings -p /Xft/DPI -s $common_dpi
    [ "$(env | grep GDK_SCALE=2)" ] || xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s $scale
fi

which feh >/dev/null 2>&1 && feh --bg-fill --no-fehbg $primary_background $secondary_background 2>/dev/null
