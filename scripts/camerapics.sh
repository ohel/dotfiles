#!/usr/bin/sh
# Download pictures from a digital camera via PictBridge/PTP/MTP using gphoto2.

folder=$(gphoto2 --list-folders | grep -o "[^ ']*DCIM/[^']*" | tail -n 1)
[ ! "$folder" ] && echo "No camera found." && sleep 3 && exit 1

warn=$(gphoto2 --list-folders | grep -o "[^ ']*DCIM/[^']*" | wc -l)

if [ "$warn" -gt 1 ]
then
    echo "There were more than one DCIM directories found."
    echo "The one chosen now is: $folder"
    echo "Press return to continue."
    read tmp
fi

gphoto2 -f $folder -L
echo
echo "Press return to download all (skip existing files)."
read tmp
gphoto2 -f $folder -P --skip-existing
echo
echo "Press return to delete all."
read tmp
gphoto2 -f $folder -D
