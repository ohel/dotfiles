#!/usr/bin/sh
# Show some status info about a WiFi interface. Assumes standard interface name, i.e. starts with wl.

nic=$(ifconfig | grep wl.*: -o | tr -d ':')
ip_addr=$(ifconfig | grep $nic -A 2 | grep -o "inet .*" | cut -f 2 -d ' ')
link_quality=$(cat /proc/net/wireless | tail -n 1 | tr -s ' ' | cut -f 3 -d ' ')
signal_quality=$(echo "$link_quality / .7" | bc)
link_info="$(iw dev $nic link)"
ssid=$(echo "$link_info" | grep SSID | cut -f 2 -d ':')
signal_strength=$(echo "$link_info" | grep "signal" | grep -o "\-.*")
rx_bitrate=$(echo "$link_info" | grep "rx bitrate" | cut -f 2 -d ':')
tx_bitrate=$(echo "$link_info" | grep "tx bitrate" | cut -f 2 -d ':')

echo $nic connected to: $ssid
echo "Quality: $signal_quality% ($signal_strength)"
echo RX bitrate:$rx_bitrate
echo TX bitrate:$tx_bitrate

if [ "$#" -gt 0 ] && [ "$1" = "pause" ]
then
    echo
    echo "Press return to continue."
    read tmp
fi
