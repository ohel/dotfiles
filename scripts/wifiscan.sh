#!/bin/sh
# Scan and list available wifi network ESSIDs.
interface=$(cat /proc/net/wireless | tail -n +3 | head -n 1 | cut -f 1 -d ':')
if test "X$interface" = "X"
then
    echo No wifi interface found.
    exit
fi

sudo iwlist $interface scan | grep ESSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/'
if [ "$#" -gt 0 ] && [ "$1" = "pause" ]; then
    echo
    echo "Press return to continue."
    read temp
fi
