#!/usr/bin/sh
# Return 0 if active window is not in check lists, 1 if it is.
# Check the output of "wmctrl -lx" to write the list files.
#
# For window classes:
#   ~/.config/check_window_classes
# Put one class per line.
# Example classes for the file e.g. to prevent closing XFCE desktop or RDP windows:
#   xfdesktop.Xfdesktop
#   org.remmina.Remmina.org.remmina.Remmina
#
# For window titles:
#   ~/.config/check_window_titles
# Put regex patterns to the file, one per line.
# Example patterns for the file to prevent accidental emerge cancellation:
#   ^HOSTNAME: Jobs:
#   ^HOSTNAME: emerge$

active_win_id_dec=$(xdotool getactivewindow)
active_win_id_hex=$(awk -v id="$active_win_id_dec" 'BEGIN { printf "%X\n", id }')
active_win_info=$(wmctrl -lx | grep -i "0x[0]*$active_win_id_hex" | tr -s ' ' | cut -f 3- -d ' ')
active_win_class=$(echo $active_win_info | cut -f 1 -d ' ')
active_win_title=$(echo $active_win_info | cut -f 3- -d ' ')

[ "$(grep "$active_win_class" ~/.config/check_window_classes 2>/dev/null)" ] ||
[ "$(echo "$active_win_title" | grep -f ~/.config/check_window_titles 2>/dev/null)" ] && exit 1

exit 0
