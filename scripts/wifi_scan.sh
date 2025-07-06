#!/usr/bin/sh
# Scan and list available WiFi network ESSIDs.
# This is often enough to make the computer reconnect to a network it should but hasn't yet connected.

interface=$(ls -l /sys/class/net | grep devices/pci | grep -o " w[^ ]* ->" | cut -f 2 -d ' ' | head -n 1)
if [ ! "$interface" ]
then
    echo No wifi interface found.
    exit 1
fi

iw $interface scan 2>/dev/null || sudo iw $interface scan | grep [^B]SSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/' | sort

if [ "$#" -gt 0 ] && [ "$1" = "pause" ]
then
    echo
    echo "Press return to continue."
    read tmp
fi
