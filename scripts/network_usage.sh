#!/bin/bash

if [ "$#" == 0 ]
then
    IF="enp4s0"
else
    IF=$1
fi

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
        echo "tx $IF: $TKBPS kB/s rx $IF: $RKBPS kB/s"
done

