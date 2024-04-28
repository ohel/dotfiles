#!/usr/bin/sh
# Add copyright info to all jpeg and mp4 files in current directory.

[ "$1" = "" ] && exit 1
exiftool "-Copyright=$1" -m -ext .jpg -ext .mp4 -overwrite_original_in_place -P .
