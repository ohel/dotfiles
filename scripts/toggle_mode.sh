#!/usr/bin/sh
# Toggles between best resolution and given mode $1 (FullHD, i.e. 1920x1080 by default) for all displays showing a picture.
# UI scaling is set also if HiDPI resolutions are being set.
# Unfortunately setting GDK_SCALE won't work on the fly since it's an environment variable.

[ ! "$DISPLAY" ] && echo "No \$DISPLAY" && exit 1

primary_background=~/.themes/background
secondary_background=~/.themes/background2
HIDPI_WIDTH=3840
target_mode=${1:-"1920x1080"}
primary_display=$2
target_is_hidpi="yes"
[ "$(echo $target_mode | cut -f 1 -d 'x')" -lt $HIDPI_WIDTH ] && target_is_hidpi=""

xrandrout="$(xrandr)"

current_mode=$(echo "$xrandrout" | grep \* | head -n 1 | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}")
[ "$current_mode" != $target_mode ] && set_target_mode="yes"

primary_display=${primary_display:-$(echo "$xrandrout" | grep " connected" | cut -f 1 -d ' ' | head -n 1)}
[ ! "$primary_display" ] && echo "Primary display not found. Try giving it as \$2." && exit 1
primary_mode=$(echo "$xrandrout" | grep -A 1 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
p_width=$(echo $primary_mode | cut -f 1 -d 'x')

# Sometimes the native resolution is not the first mode line, but the second. This might be the case with e.g. 4K televisions.
mode_candidate=$(echo "$xrandrout" | grep -A 2 $primary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
mc_width=$(echo $mode_candidate | grep -o "^[0-9]\{3,4\}")
([ $p_width -gt $HIDPI_WIDTH ] || ([ $mc_width -le $HIDPI_WIDTH ] && [ $(echo $primary_mode | grep -o "^[0-9]\{3,4\}") -lt $mc_width ])) && primary_mode=$mode_candidate
primary_native=$primary_mode

echo "Primary display: $primary_display, native mode: $primary_native"

secondary_display=$(echo "$xrandrout" | grep " connected" | cut -f 1 -d ' ' | grep -v $primary_display | head -n 1)
if [ "$secondary_display" ]
then
    secondary_mode=$(echo "$xrandrout" | grep -A 1 $secondary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
    mode_candidate=$(echo "$xrandrout" | grep -A 2 $secondary_display | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n 1)
    mc_width=$(echo $mode_candidate | grep -o "^[0-9]\{3,4\}")
    s_width=$(echo $secondary_mode | cut -f 1 -d 'x')
    ([ $s_width -gt $HIDPI_WIDTH ] || ([ $mc_width -le $HIDPI_WIDTH ] && [ $(echo $secondary_mode | grep -o "^[0-9]\{3,4\}") -lt $mc_width ])) && secondary_mode=$mode_candidate
    secondary_native=$secondary_mode
    echo "Secondary display: $secondary_display, native mode: $secondary_native"
fi

# An active mode is marked with * in xrandr output. Each display is either _c_onnected or dis_c_onnected. By deleting all other characters, we know if the display is actually showing a picture.
has_primary=$(echo "$xrandrout" | grep -z -o "$primary_display.*[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n +2 | tr -c -d [*c] | cut -f 1 -d 'c')
has_secondary=$(echo "$xrandrout" | grep -z -o "$secondary_display.*[0-9]\{3,4\}x[0-9]\{3,4\}" | tail -n +2 | tr -c -d [*c] | cut -f 1 -d 'c')

[ "$set_target_mode" ] && primary_mode=$target_mode && secondary_mode=$target_mode && echo "Setting mode $target_mode"
if [ ! "$secondary_display" ]
then
    echo No secondary display found.
    xrandr --output $primary_display --mode $primary_mode --primary
else
    [ "$(echo "$xrandrout" | grep "primary")" ] || noprimary="--noprimary"
    primary_output=""
    secondary_output=""
    [ "$has_primary" ] && primary_output="--output $primary_display --mode $primary_mode $noprimary"
    [ "$has_secondary" ] && secondary_output="--output $secondary_display --mode $secondary_mode"
    xrandr $primary_output $secondary_output
    secondary_background=""
    echo "Set modes $primary_mode$has_primary, $secondary_mode$has_secondary."
fi

# Xrandr only shows the physical size if the display is connected, therefore we need to call xrandr again.
# Sometimes the size does not actually match real world; one can export primary display override env var DPI per-system.
xrandrout="$(xrandr)"
p_phys_width=$(echo "$xrandrout" | grep -A 1 $primary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$p_phys_width" ] && [ $p_phys_width -gt 0 ] && [ "$has_primary" ]
then
    p_dpi_calc=$(echo "scale=2; $p_width / $p_phys_width * 25.4" | bc | cut -f 1 -d '.')
    p_dpi_set=96
    [ $p_dpi_calc -gt 100 ] && p_dpi_set=112
    [ $p_dpi_calc -gt 140 ] && [ $p_phys_width -gt 300 ] && p_dpi_set=144
    if [ "$set_target_mode" ]
    then
        p_mode_width=$(echo $primary_mode | cut -f 1 -d 'x')
        p_native_width=$(echo $primary_native | cut -f 1 -d 'x')
        p_dpi_set=$(echo "scale=2; $p_mode_width / $p_native_width * $p_dpi_set" | bc | cut -f 1 -d '.')
        [ $p_dpi_set -lt 96 ] && p_dpi_set=96
    else
        [ "$DPI" ] && p_dpi_set=$DPI
    fi
    common_dpi=$p_dpi_set
fi

scale=1
[ $p_width -eq $HIDPI_WIDTH ] && [ "$has_primary" ] && scale=2
[ "$set_target_mode" ] && [ ! "$target_is_hidpi" ] && scale=1

[ "$secondary_display" ] && s_phys_width=$(echo "$xrandrout" | grep -A 1 $secondary_display | grep -o [0-9]*mm | head -n 1 | tr -d [:alpha:])
if [ "$s_phys_width" ] && [ $s_phys_width -gt 0 ] && [ "$has_secondary" ]
then
    s_dpi_calc=$(echo "scale=2; $s_width / $s_phys_width * 25.4" | bc | cut -f 1 -d '.')
    s_dpi_set=96
    [ $s_dpi_calc -gt 100 ] && s_dpi_set=112
    [ $s_dpi_calc -gt 140 ] && [ $s_phys_width -gt 300 ] && s_dpi_set=144
    [ $s_width -eq $HIDPI_WIDTH ] && scale=2
    [ "$set_target_mode" ] && [ ! "$target_is_hidpi" ] && scale=1
    if [ "$set_target_mode" ]
    then
        s_mode_width=$(echo $secondary_mode | cut -f 1 -d 'x')
        s_native_width=$(echo $secondary_native | cut -f 1 -d 'x')
        s_dpi_set=$(echo "scale=2; $s_mode_width / $s_native_width * $s_dpi_set" | bc | cut -f 1 -d '.')
        [ $s_dpi_set -lt 96 ] && s_dpi_set=96
    fi
    (! [ "$common_dpi" ] || [ $s_dpi_set -lt $p_dpi_set ]) && common_dpi=$s_dpi_set
fi

# HiDPI (4K) displays need some magic. Not all applications (e.g. GTK2) support scaling, so double the DPI is required for them to look "normal".
# However, we only want this if GDK is set to scale down font sizes accordingly. Otherwise the window scaling factor xsetting should be used.
[ ! "$common_dpi" ] && common_dpi=96
echo Final DPI: $common_dpi
[ ! "$set_target_mode" ] && [ "$(env | grep GDK_DPI_SCALE=0.5)" ] && common_dpi=$(expr 2 \* $common_dpi)

if [ "$(which xfconf-query 2>/dev/null)" ]
then
    xfconf-query -c xsettings -p /Xft/DPI -s $common_dpi
    xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s 1
    ([ ! "$(env | grep GDK_SCALE=2)" ] || [ "$set_target_mode" ]) && xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s $scale
    xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s $(expr $scale \* 20 + 1)
fi

which feh >/dev/null 2>&1 && feh --bg-fill --no-fehbg $primary_background $secondary_background 2>/dev/null

# Reloads icons so that they scale correctly.
ps -ef | grep -q "xfce4-panel$" && xfce4-panel -r
