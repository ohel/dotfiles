#!/bin/sh
# Download pictures from Nikon Coolpix S7000 via MTP using gphoto2.

folder="/store_00010001/DCIM/100NIKON"

gphoto2 -f $folder -L
echo
echo "Press return to download all."
read tmp
gphoto2 -f $folder -P
echo
echo "Press return to delete all."
read tmp
gphoto2 -f $folder -D
