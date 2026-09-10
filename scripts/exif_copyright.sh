#!/usr/bin/sh
# Add copyright info to certain media files in current directory.

[ "$1" = "" ] && exit 1
exiftool "-Copyright=$1" -m -ext jpg -ext webp -ext mp4 -overwrite_original_in_place -P .
