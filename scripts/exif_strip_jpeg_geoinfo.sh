#!/usr/bin/sh
# Remove GPS info from all jpeg files in current directory.

exiftool "-gps:all=" -m -ext .jpg -overwrite_original_in_place -P .
