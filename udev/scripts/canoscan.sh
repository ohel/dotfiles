#!/bin/bash

export XAUTHORITY=/home/panther/.Xauthority
export DISPLAY=:0.0

cp /home/panther/.scripts/udev/canoscan_scanscript.sh /dev/shm/scan
chmod +x /dev/shm/scan

