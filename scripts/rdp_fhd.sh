#!/usr/bin/sh
# Connect to a remote computer using xfreerdp, using scaled (when full screen) FullHD resolution.
# Remote is assumed to have an IP address: x.y.z.$1 (where xyz match those of the host, $1 defaults to 20)
# User may be given as $2, defaults to current. $3 is other arguments to xfreerdp.

nic=$(ip route show default | awk '{print $5}')
ip=$(ip -4 addr show "$nic" | awk '/inet / {print $2}' | cut -d '/' -f 1)
lan_prefix=$(ip -4 route show dev "$nic" scope link | awk '{print $1}' | head -n 1 | cut -f -3 -d '.')

remote_ip=$lan_prefix.${1:-20}
user=${2:-$(whoami)}

echo "Connecting to $remote_ip" as $user.
echo "Press Ctrl+Alt+Return to toggle full screen."
echo "Press right Ctrl to release grabbed keyboard."

# Audio-mode 1 leaves sound on server, 2 disables audio.
# Flags +fonts and +keyboard-grab are already enabled by default.
xfreerdp /v:$remote_ip /u:$user /d:"" /smart-sizing:1920x1080 /network:lan /bpp:24 /cache:glyph:on /audio-mode:1 +f -floatbar -drives -decorations -compression $3
