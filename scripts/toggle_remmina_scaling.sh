#!/bin/sh

conf=~/.config/remmina/remmina.pref

sf=$(grep rdp_desktopScaleFactor $conf | cut -f 2 -d '=')
[ $sf -eq 100 ] && sf=200 || sf=100
new_sf=${1:-$sf}

sed -i "s/rdp_desktopScaleFactor=[12]00/rdp_desktopScaleFactor=$new_sf/" $conf
