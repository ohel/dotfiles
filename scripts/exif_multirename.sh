#!/bin/sh
# Given filenames ending in .jpg, .JPG, .RW2 or .RW2.xmp, rename a matching JPEG file as:
# YYYY-mm-dd_HH.MM.SS_<input>.jpg, where <input> is an optional zenity input. Exiftool is used for reading metadata.
# If a similarly named .RW2 or .RW2.xmp file exists, they are renamed too, and the file name updated to .RW2.xmp.
# If no description (in file name after timestamp) is given for a single file but a previous one exists, the old one is used.
# If multiple filenames are given, the _<input> is omitted from the end of the file name.

[ ! "$1" ] && echo "Missing arguments." && exit 1
[ ! $(which exiftool 2>/dev/null) ] && echo "Missing exiftool." && exit 1

use_desc_sep="_"
[ "$#" -gt 1 ] && use_desc_sep=""

width=$(echo "$(xrandr | grep -o "current [0-9]*" | cut -f 2 -d ' ') / 4" | bc)

for fn in "$@"
do
    basename=$(basename -s .jpg "$fn")
    [ "$basename" = "$fn" ] && basename=$(basename -s .JPG "$fn")
    [ "$basename" = "$fn" ] && basename=$(basename -s .RW2 "$fn")
    [ "$basename" = "$fn" ] && basename=$(basename -s .RW2.xmp "$fn")

    originalname=""
    [ -e "$basename.jpg" ] && originalname="$basename.jpg"
    [ -e "$basename.JPG" ] && originalname="$basename.JPG"

    if [ ! "$originalname" ]
    then
        echo "JPEG file not found: $originalname"
        [ "$use_desc_sep" ] && exit 1
        echo "File probably already renamed, continuing batch."
        continue
    fi

    desc=""
    [ "$use_desc_sep" ] && [ $(which zenity 2>/dev/null) ] && [ "$width" ] && desc=$(zenity --title="New filename" --text="Enter filename after timestamp, or leave empty to use current:" --entry --width=$width)
    [ "$use_desc_sep" ] && [ ! "$desc" ] && desc=$(echo $basename | grep "[0-9]\{4\}-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]_.*" | cut -f 3- -d '_')

    timestamp=$(exiftool -CreateDate -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
    newbasename="$timestamp$use_desc_sep$desc"

    postfix=""
    if [ -e "$newbasename.jpg" ]
    then
        index=$(ls -1 "$newbasename"*.jpg | wc -l)
        postfix="_$index"
    fi

    mv "$originalname" "$newbasename$postfix.jpg"
    [ -e "$basename.RW2" ] && mv "$basename.RW2" "$newbasename$postfix.RW2"
    [ -e "$basename.RW2.xmp" ] && sed -i -s "s/$basename.RW2/$newbasename$postfix.RW2/" "$basename.RW2.xmp"
    [ -e "$basename.RW2.xmp" ] && mv "$basename.RW2.xmp" "$newbasename$postfix.RW2.xmp"
done
