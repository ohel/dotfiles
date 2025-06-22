#!/usr/bin/sh
# Show some status info about a WiFi interface. Assumes standard interface name, i.e. starts with wl.

nic=$(ifconfig | grep wl.*: -o | tr -d ':')
[ ! "$nic" ] && echo No wireless interface found. && exit 1
ip_addr=$(ifconfig | grep $nic -A 2 | grep -o "inet .*" | cut -f 2 -d ' ')
link_quality=$(cat /proc/net/wireless 2>/dev/null | tail -n 1 | tr -s ' ' | cut -f 3 -d ' ' | tr -d '.|')
link_quality=$(echo "$link_quality. / .7" | bc)
link_info="$(iw dev $nic link)"
ssid=$(echo " $link_info" | grep SSID | cut -f 2 -d ':')
signal_strength=$(echo " $link_info" | grep "signal" | grep -o "\-.*")
rx_bitrate=$(echo " $link_info" | grep "rx bitrate" | cut -f 2 -d ':')
tx_bitrate=$(echo " $link_info" | grep "tx bitrate" | cut -f 2 -d ':')
wifi_gen=4
echo " $rx_bitrate" | grep VHT >/dev/null && wifi_gen=5
echo " $rx_bitrate" | grep HE >/dev/null && wifi_gen=6
echo " $rx_bitrate" | grep EHT >/dev/null && wifi_gen=7

echo "Interface: $nic | SSID:$ssid | Standard: Wi-Fi $wifi_gen | IP: $ip_addr"
echo RX bitrate:$rx_bitrate
echo TX bitrate:$tx_bitrate
echo "Quality: $link_quality% ($signal_strength)"
