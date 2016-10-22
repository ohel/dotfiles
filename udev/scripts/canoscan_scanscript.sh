#!/bin/bash
# Batch scanning script for Canon Lide scanner. An ugly hack for single user desktops.
# The scanner or the driver has a bug which causes the scanning operation to fail sometimes.
# This script takes care of that. There also is (or at least used to be) a bug which causes
# the scans to be weirdly deformed unless color mode and high resolution is used.

# The corresponding udev script could be for example something like:
# ACTION=="add", ENV{SUBSYSTEM}=="usb", ENV{ID_VENDOR}=="Canon", ENV{ID_MODEL}=="CanoScan", RUN+="/bin/su panther -c '/bin/bash ~/.scripts/udev/canoscan.sh'", SYMLINK="canoscan", MODE="0666"

# And the corresponding canoscan.sh script:
# export XAUTHORITY=/home/panther/.Xauthority
# export DISPLAY=:0.0
# cp /home/panther/.scripts/udev/canoscan_scanscript.sh /dev/shm/scan
# chmod +x /dev/shm/scan

# Finally one just needs to run the scan script from /dev/shm (e.g. via .desktop shortcut).

scanimagebin="/usr/bin/scanimage"
scanner="genesys:libusb:"$(ls -la /dev/canoscan | cut -f 2 -d '>' | cut -f 3-4 -d '/' | sed "s/\//\:/")
scandir=/tmp/scans

mkdir -p $scandir

while [ 1 ]
do
    num=$(find $scandir/ -size +0k -iname "scan*.png" | wc -l)
    echo -n "Scanning scan$num.png..."
    errors=1
    while [ $errors -gt 0 ]
    do
        $scanimagebin -d $scanner --mode Color --resolution 300 -p > $scandir/scan$num.png 2>$scandir/scanlog.txt
        errors=$(cat $scandir/scanlog.txt | wc -l)
        if [ $errors -gt 0 ]
        then
            rm $scandir/scanlog.txt
            echo -n "."
        else
            rm $scandir/scanlog.txt
            echo
            echo "Press return to scan again, Ctrl-C to quit."
            read
        fi
    done
done

