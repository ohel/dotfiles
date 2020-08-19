#!/bin/sh
# Copy tags from one file to another, clearing everything from the destination file. Ask for optional user description tag to add.

[ "$1" = "" ] && exit 1
[ "$2" = "" ] && exit 1
exiftool -all= -tagsFromFile "$1" -exif:all "$2" -P
echo "Type in optional description for the destination image:"
read description
[ "$description" = "" ] && exit 0
exiftool -ImageDescription="$description" -overwrite_original_in_place -P "$2"
