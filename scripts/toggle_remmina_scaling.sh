#!/usr/bin/sh
# Toggles scaling factor for Remmina RDP connections between 100% and 200%.
# It's useful to scale when you have a high-DPI display and connect via high-resolution RDP.

conf=~/.config/remmina/remmina.pref

sf=$(grep rdp_desktopScaleFactor $conf | cut -f 2 -d '=')
[ $sf -eq 100 ] && sf=150 || sf=100
new_sf=${1:-$sf}

sed -i "s/rdp_desktopScaleFactor=1[50]0/rdp_desktopScaleFactor=$new_sf/" $conf
