#!/bin/sh
# Return 0 if active window is OK to close, 1 if it is in one of the "do not close" lists.
# Check the output of "wmctrl -lx" to write the list files.
#
# For window classes:
#   ~/.config/no_close_window_classes
# Put one class per line.
# Example classes for the file to prevent closing XFCE desktop or RDP windows:
#   xfdesktop.Xfdesktop
#   remmina.org.remmina.Remmina
#
# For window titles:
#   ~/.config/no_close_window_titles
# Put regex patterns to the file, one per line.
# Example patterns for the file to prevent accidental emerge cancellation:
#   ^HOSTNAME Jobs:
#   ^HOSTNAME emerge$

active_win_id_dec=$(xdotool getactivewindow)
active_win_id_hex=$(echo "obase=16; $active_win_id_dec" | bc)
active_win_class=$(wmctrl -lx | grep -i "0x0$active_win_id_hex" | tr -s ' ' | cut -f 3 -d ' ')
active_win_title=$(wmctrl -lx | grep -i "0x0$active_win_id_hex" | tr -s ' ' | cut -f 4- -d ' ')

[ "$(grep "$active_win_class" ~/.config/no_close_window_classes 2>/dev/null)" ] ||
[ "$(echo "$active_win_title" | grep -f ~/.config/no_close_window_titles 2>/dev/null)" ] && exit 1

exit 0
