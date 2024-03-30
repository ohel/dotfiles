#!/usr/bin/sh
# Scan and list available wifi network ESSIDs.

interface=$(ls -l /sys/class/net | grep devices/pci | grep -o " w[^ ]* ->" | cut -f 2 -d ' ' | head -n 1)
if [ ! "$interface" ]
then
    echo No wifi interface found.
    exit 1
fi

if [ "$(which iw 2>/dev/null)" ]
then
    sudo iw $interface scan | grep [^B]SSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/' | sort
else
    sudo iwlist $interface scan | grep ESSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/' | sort
fi

if [ "$#" -gt 0 ] && [ "$1" = "pause" ]
then
    echo
    echo "Press return to continue."
    read tmp
fi
