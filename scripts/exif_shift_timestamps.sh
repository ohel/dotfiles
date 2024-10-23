#!/usr/bin/sh
# Shift EXIF dates for files of supported file types in current directory + or - given hours, minutes and seconds.

echo "Change EXIF dates of .jpg, .RW2, CR3, .mp4 and .mov files in current directory."
echo "Usage: exif_shift_timestamps.sh +|- h m s"
echo "Press return to continue, Ctrl-C to cancel."
read tmp
exiftool -ext jpg -ext rw2 -ext cr3 -ext mp4 -ext mov -m -overwrite_original -AllDates$1=$2:$3:$4 .
