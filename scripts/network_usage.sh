#!/bin/bash
# Show network usage (up/down kB/s) for interface $1 if given, or for
# the first non-loopback interface with IPv4 address listed by ifconfig if not given.

if [ "$#" == 0 ]
then
    ip=$(ifconfig | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep -v "127.0.0.1" | head -n 1 | tr -s ' ' | cut -f 3 -d ' ')
    IF=$(ifconfig | grep -B 1 $ip | head -n 1 | cut -f 1 -d ':')
else
    IF=$1
fi

echo "Monitoring interface: $IF"
echo "u = up = tx_bytes [kB/s]"
echo "d = down = rx_bytes [kB/s]"
echo
while true
do
    R1=`cat /sys/class/net/$IF/statistics/rx_bytes`
    T1=`cat /sys/class/net/$IF/statistics/tx_bytes`
    sleep 1
    R2=`cat /sys/class/net/$IF/statistics/rx_bytes`
    T2=`cat /sys/class/net/$IF/statistics/tx_bytes`
    TBPS=`expr $T2 - $T1`
    RBPS=`expr $R2 - $R1`
    TKBPS=`expr $TBPS / 1024`
    RKBPS=`expr $RBPS / 1024`
    echo "u: $TKBPS | d: $RKBPS"
done

