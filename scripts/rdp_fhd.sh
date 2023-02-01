#!/bin/sh
# Connect to a remote computer using xfreerdp, using scaled (when full screen) FullHD resolution.
# Remote is assumed to have an IP address: x.y.0.$1 (where x and y match those of the host)
# User may be given as $2, defaults to current. $3 is other arguments to xfreerdp.

for physical_device in $(ls -l /sys/class/net | grep devices/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
do
    ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
    if [ "$ip" ]
    then
        lannet=$(echo $ip | cut -f 1 -d '.')
        break
    fi
done
subnet=0 # 10.0.x.x
[ "$lannet" = "192" ] && subnet=168 # 192.168.x.x
remote_ip=$lannet.$subnet.0.${1:-20}
user=${2:-$(whoami)}

echo "Connecting to $remote_ip" as $user.
echo "Press Ctrl+Alt+Return to toggle full screen."
echo "Press right Ctrl to release grabbed keyboard."

xfreerdp /v:$remote_ip /smart-sizing:1920x1080 /f /network:lan /u:$user /bpp:24 +glyph-cache +fonts +grab-keyboard /audio-mode:1 -drives -floatbar -decorations -compression $3
