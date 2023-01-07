#!/bin/sh
# Copy tags from one file to another, clearing everything from the destination file, except for the thumbnail. Ask for optional user description tag to add.
# Tags can also be added instead of copied.

if [ "$2" = "" ]
then
    echo "Copy (overwrite) or add (insert new) tags from source file to destination file."
    echo "Usage: $0 source destination [mode]"
    echo "where mode: add|copy (defaults to: copy)"
    exit 1
fi

copymode=1
[ "$3" = "add" ] && copymode=0

thumb=$(mktemp)
exiftool -b -ThumbnailImage "$2" > $thumb

if [ $copymode -eq 1 ]
then
    exiftool -all= -tagsFromFile "$1" -exif:all "$2" -P -overwrite_original_in_place
else
    exiftool -addTagsFromFile "$1" -exif:all "$2" -P -overwrite_original_in_place
fi

if [ $(du -b $thumb | grep -o "^[0-9]*") -gt 0 ]
then
    exiftool "-ThumbnailImage<=$thumb" -overwrite_original_in_place -P "$2"
    echo Set thumbnail image.
fi

[ $copymode -eq 0 ] && exit 0

echo "Type in optional description for the destination image:"
read description
[ "$description" = "" ] && exit 0
exiftool -ImageDescription="$description" -overwrite_original_in_place -P "$2"
