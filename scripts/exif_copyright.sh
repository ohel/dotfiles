#!/usr/bin/sh
# Add copyright info to all jpeg files in current directory.

[ "$1" = "" ] && exit 1
exiftool "-Copyright=$1" -m -ext .jpg -overwrite_original_in_place -P .
