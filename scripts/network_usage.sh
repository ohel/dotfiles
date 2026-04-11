#!/usr/bin/sh
# Show network usage (up/down MB/s) for interface $1 if given,
# or by default for the first PCI interface with IPv4 address.
# Only updates when speed changes enough to show on MB/s scale.

nic=$(ip route show default | awk '{print $5}')
[ "$#" != 0 ] && nic=$1

echo "Monitoring interface: $nic"
echo "Only updates nic notable change occurs - small traffic may seem nonexistent."
echo
echo " Unit: [MB/s]"
echo "-------------"
echo "   UP |  DOWN"
echo "      |"
tx_mbps_old=-1
rx_mbps_old=-1
while true
do
    rx1=$(cat /sys/class/net/$nic/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$nic/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$nic/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$nic/statistics/tx_bytes)
    tx_bps=$(expr $tx2 - $tx1)
    rx_bps=$(expr $rx2 - $rx1)
    tx_mbps=$(awk -v bps=$tx_bps 'BEGIN { printf "%.2f", bps / 1048576 }')
    rx_mbps=$(awk -v bps=$rx_bps 'BEGIN { printf "%.2f", bps / 1048576 }')
    if [ "$tx_mbps" != "$tx_mbps_old" ] || [ "$rx_mbps" != "$rx_mbps_old" ]
    then
        printf "%5s | %5s\n" "$tx_mbps" "$rx_mbps"
        tx_mbps_old=$tx_mbps
        rx_mbps_old=$rx_mbps
    fi
done
