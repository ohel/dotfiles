#!/usr/bin/sh
# Show network usage (up/down MB/s) for interface $1 if given,
# or by default for the first PCI interface with IPv4 address.
# Only updates when speed changes enough to show on MB/s scale.

if [ "$#" = 0 ]
then
    for physical_device in $(ls -l /sys/class/net | grep devices/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
    do
        ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
        if [ "$ip" ]
        then
            nic=$physical_device
            break
        fi
    done
else
    nic=$1
fi

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
    tx_mbps=$(echo "scale=2; $tx_bps / 1048576" | bc)
    rx_mbps=$(echo "scale=2; $rx_bps / 1048576" | bc)
    if [ "$tx_mbps" != "$tx_mbps_old" ] || [ "$rx_mbps" != "$rx_mbps_old" ]
    then
        printf "%5s | %5s\n" "$tx_mbps" "$rx_mbps"
        tx_mbps_old=$tx_mbps
        rx_mbps_old=$rx_mbps
    fi
done
