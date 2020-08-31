#!/bin/sh
# Toggles between best resolution and FullHD for all connected displays.
# UI scaling is set also. Unfortunately setting GDK_SCALE won't work on the fly since it's an environment variable.
# A display is considered connected even if it's not showing any picture.

primary_background=~/.themes/background
secondary_background=~/.themes/background2
HIDPI_WIDTH=3840
FULLHD="1920x1080"

xrandrout="$(xrandr)"

current_mode=$(echo "$xrandrout" | grep \* | head -n 1 | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}")
[ "$current_mode" != $FULLHD ] && set_fhd=1

primary_display=${primary_display:-$(echo "$xrandrout" | grep " connected" | cut -f 1 -d ' ' | head -n 1)}
primary_mode=$(echo "$xrandrout" | grep -A 1 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
p_width=$(echo $primary_mode | cut -f 1 -d 'x')

# Sometimes the native resolution is not the first mode line, but the second. This might be the case with e.g. 4K televisions.
mode_candidate=$(echo "$xrandrout" | grep -A 2 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
mc_width=$(echo $mode_candidate | grep -o "^[0-9]\{3,4\}")
([ $p_width -gt $HIDPI_WIDTH ] || ([ $mc_width -le $HIDPI_WIDTH ] && [ $(echo $primary_mode | grep -o "^[0-9]\{3,4\}") -lt $mc_width ])) && primary_mode=$mode_candidate

echo "Primary display: $primary_display, mode: $primary_mode"

secondary_display=$(echo "$xrandrout" | grep " connected" | cut -f 1 -d ' ' | grep -v $primary_display | head -n 1)
if [ "$secondary_display" ]
then
    secondary_mode=$(echo "$xrandrout" | grep -A 1 $secondary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
    mode_candidate=$(echo "$xrandrout" | grep -A 2 $secondary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
    mc_width=$(echo $mode_candidate | grep -o "^[0-9]\{3,4\}")
    s_width=$(echo $secondary_mode | cut -f 1 -d 'x')
    ([ $s_width -gt $HIDPI_WIDTH ] || ([ $mc_width -le $HIDPI_WIDTH ] && [ $(echo $secondary_mode | grep -o "^[0-9]\{3,4\}") -lt $mc_width ])) && secondary_mode=$mode_candidate
    echo "Secondary display: $secondary_display, mode: $secondary_mode"
fi

[ "$set_fhd" ] && primary_mode=$FULLHD && secondary_mode=$FULLHD && echo "Setting FullHD."
if [ ! "$secondary_display" ]
then
    echo No secondary display found.
    xrandr --output $primary_display --mode $primary_mode --primary
else
    [ "$(echo "$xrandrout" | grep "primary")" ] || noprimary="--noprimary"
    xrandr --output $primary_display --mode $primary_mode $noprimary \
        --output $secondary_display --mode $secondary_mode
    secondary_background=""
    echo "Set modes $primary_mode, $secondary_mode."
fi

# Xrandr only shows the physical size if the display is connected, therefore we need to call xrandr again.
# Sometimes the size does not actually match real world. In that case, one can export DPI per-system in e.g. ~/.profile.env_extra
xrandrout="$(xrandr)"
p_phys_width=$(echo "$xrandrout" | grep -A 1 $primary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$p_phys_width" ]
then
    p_dpi_calc=$(echo "scale=2; $p_width / $p_phys_width * 25.4" | bc | cut -f 1 -d '.')
    p_dpi_set=96
    [ $p_dpi_calc -gt 100 ] && p_dpi_set=112
    [ $p_dpi_calc -gt 140 ] && [ $p_phys_width -gt 300 ] && p_dpi_set=144
    [ "$set_fhd" ] || [ "$DPI" ] && p_dpi_set=$DPI
    common_dpi=$p_dpi_set
fi

scale=1
[ $p_width -eq $HIDPI_WIDTH ] && scale=2

[ "$secondary_display" ] && s_phys_width=$(echo "$xrandrout" | grep -A 1 $secondary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$s_phys_width" ]
then
    s_phys_width=$(echo "$xrandrout" | grep -A 1 $secondary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
    s_dpi_calc=$(echo "scale=2; $s_width / $s_phys_width * 25.4" | bc | cut -f 1 -d '.')
    s_dpi_set=96
    [ $s_dpi_calc -gt 100 ] && s_dpi_set=112
    [ $s_dpi_calc -gt 140 ] && [ $s_phys_width -gt 300 ] && s_dpi_set=144
    [ $s_width -eq $HIDPI_WIDTH ] && scale=2
    (! [ "$common_dpi" ] || [ $s_dpi_set -lt $p_dpi_set ]) && common_dpi=$s_dpi_set
fi

# HiDPI (4K) displays need some magic. Not all applications (e.g. GTK2) support scaling, so double the DPI is required for them to look "normal".
# However, we only want this if GDK is set to scale down font sizes accordingly. Otherwise the window scaling factor xsetting should be used.
[ ! "$set_fhd" ] && [ "$(env | grep GDK_DPI_SCALE=0.5)" ] && common_dpi=$(expr 2 \* $common_dpi)
echo Final DPI: $common_dpi

if [ $(which xfconf-query >/dev/null 2>&1) ]
then
    xfconf-query -c xsettings -p /Xft/DPI -s $common_dpi
    ([ ! "$(env | grep GDK_SCALE=2)" ] || [ "$set_fhd" ]) && xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s $scale
    xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s $(expr $scale \* 20 + 1)
fi

which feh >/dev/null 2>&1 && feh --bg-fill --no-fehbg $primary_background $secondary_background 2>/dev/null
