#!/bin/sh
# Helper script for starting to batch scan.

if [ ! -e /dev/shm/scan ]
then
    exit
fi
setsid thunar /tmp/scans &>/dev/null &
~/.scripts/canoscan.sh
