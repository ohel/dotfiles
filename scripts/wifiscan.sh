#!/bin/sh
# Scan and list available wifi network ESSIDs.
sudo iwlist wlp1s0 scan | grep ESSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/'
