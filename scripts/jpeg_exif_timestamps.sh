#!/bin/bash
echo "Usage: jpeg_exif_timestamps.sh +|- h m s"
echo "Press return to accept, CTRL-C to cancel."
read
exiftool -ext .jpg -overwrite_original -AllDates$1=$2:$3:$4 .

