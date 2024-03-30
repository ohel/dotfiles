#!/usr/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

while true
do
    column=2
    for idletimes in $(mpstat -P ALL 1 1 | tr -s [' '] | grep "Average: \w " | cut -f 11 -d ' ')
    do
        usage=$(echo "(100.0-$idletimes)/6.25" | bc)
        if [ $usage -eq 16 ]
        then
            usagestring="20"
        elif [ $usage -gt 7 ]
        then
            usagestring="1"$(expr $usage - 8)
        else
            usagestring="0"$usage
        fi
        echo -e "\xFE\x3D\002$column\00$usagestring" > /dev/serial/matrix_orbital
        sleep 0.01
        column=$(expr $column + 1)
    done
done
