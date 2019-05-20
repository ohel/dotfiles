#!/bin/sh
# Download pictures from a digital camera via PictBridge/PTP/MTP using gphoto2.

# Assuming there is only one folder under DCIM.
folder=$(gphoto2 --list-folders | grep -o "[^ ']*DCIM/[^']*")
[ ! "$folder" ] && echo "No camera found." && sleep 3 && exit 1

gphoto2 -f $folder -L
echo
echo "Press return to download all (skip existing files)."
read tmp
gphoto2 -f $folder -P --skip-existing
echo
echo "Press return to delete all."
read tmp
gphoto2 -f $folder -D
