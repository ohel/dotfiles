#!/bin/bash

export XAUTHORITY=/home/panther/.Xauthority
export DISPLAY=:0.0

cp /home/panther/.scripts/udev/canoscan_scanscript.sh /home/panther/ramdisk/scan
chmod +x /home/panther/ramdisk/scan

