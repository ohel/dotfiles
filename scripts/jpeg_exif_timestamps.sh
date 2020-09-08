#!/bin/sh
# Change exif dates of .jpg files in current directory + or - given hours, minutes and seconds.

echo "Change exif dates of .jpg files in current directory."
echo "Usage: jpeg_exif_timestamps.sh +|- h m s"
echo "Press return to continue, Ctrl-C to cancel."
read tmp
exiftool -ext .jpg -m -overwrite_original -AllDates$1=$2:$3:$4 .
