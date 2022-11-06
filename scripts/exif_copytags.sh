#!/bin/sh
# Copy tags from one file to another, clearing everything from the destination file, except for the thumbnail. Ask for optional user description tag to add.

if [ "$2" = "" ]
then
    echo Copy tags from source file to destination file.
    echo Usage: $0 source destination
    exit 1
fi

thumb=$(mktemp)
exiftool -b -ThumbnailImage "$2" > $thumb
exiftool -all= -tagsFromFile "$1" -exif:all "$2" -P
if [ $(du -b $thumb | grep -o "^[0-9]*") -gt 0 ]
then
    exiftool "-ThumbnailImage<=$thumb" -overwrite_original_in_place -P "$2"
    echo Set thumbnail image.
fi
echo "Type in optional description for the destination image:"
read description
[ "$description" = "" ] && exit 0
exiftool -ImageDescription="$description" -overwrite_original_in_place -P "$2"
