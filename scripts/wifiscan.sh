#!/bin/sh
# Scan and list available wifi network ESSIDs.
sudo iwlist wlp1s0 scan | grep ESSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/'
if [ "$#" -gt 0 ] && [ "$1" = "pause" ]; then
    echo
    echo "Press return to continue."
    read
fi
