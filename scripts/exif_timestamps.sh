#!/bin/sh
# Change exif dates of .jpg and .rw2 files in current directory + or - given hours, minutes and seconds.

echo "Change exif dates of .jpg and .rw2 files in current directory."
echo "Usage: exif_timestamps.sh +|- h m s"
echo "Press return to continue, Ctrl-C to cancel."
read tmp
exiftool -ext .jpg -ext rw2 -m -overwrite_original -AllDates$1=$2:$3:$4 .
