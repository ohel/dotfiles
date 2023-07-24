#!/bin/sh
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
            IF=$physical_device
            break
        fi
    done
else
    IF=$1
fi

echo "Monitoring interface: $IF"
echo "Only updates if notable change occurs - small traffic may seem nonexistent."
echo
echo " Unit: [MB/s]"
echo "-------------"
echo "   UP |  DOWN"
echo "      |"
pad="     "
TMBPS_old=-1
RMBPS_old=-1
while true
do
    R1=$(cat /sys/class/net/$IF/statistics/rx_bytes)
    T1=$(cat /sys/class/net/$IF/statistics/tx_bytes)
    sleep 1
    R2=$(cat /sys/class/net/$IF/statistics/rx_bytes)
    T2=$(cat /sys/class/net/$IF/statistics/tx_bytes)
    TBPS=$(expr $T2 - $T1)
    RBPS=$(expr $R2 - $R1)
    TMBPS=$(echo "scale=2; $TBPS / 1048576" | bc)
    RMBPS=$(echo "scale=2; $RBPS / 1048576" | bc)
    if [ "$TMBPS" != "$TMBPS_old" ] || [ "$RMBPS" != "$RMBPS_old" ]
    then
        printf "%s | %s\n" "${pad:${#TMBPS}}$TMBPS" "${pad:${#RMBPS}}$RMBPS"
        TMBPS_old=$TMBPS
        RMBPS_old=$RMBPS
    fi
done
