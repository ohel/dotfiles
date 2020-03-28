#!/bin/sh
# Given a .jpg, .JPG, .RW2 or .RW2.xmp file, rename the jpeg file as:
# YYYY-mm-dd_HH.MM.SS_<input>.jpg, where <input> is an optional zenity input. Exiftool is used for reading metadata.
# If a similarly named .RW2 or .RW2.xmp file exists, they are renamed too, and the file name updated to .RW2.xmp.

[ ! "$1" ] && exit 1

basename=$(basename -s .jpg "$1")
[ "$basename" = "$1" ] && basename=$(basename -s .JPG "$1")
[ "$basename" = "$1" ] && basename=$(basename -s .RW2 "$1")
[ "$basename" = "$1" ] && basename=$(basename -s .RW2.xmp "$1")

originalname=""
[ -e "$basename.jpg" ] && originalname="$basename.jpg"
[ -e "$basename.JPG" ] && originalname="$basename.JPG"

[ ! "$originalname" ] && echo "Jpeg file not found." && exit 1

filename=""
width=$(echo "$(xrandr | grep -o "current [0-9]*" | cut -f 2 -d ' ') / 4" | bc)
[ $(which zenity 2>/dev/null) ] && filename=$(zenity --title="New filename" --text="Enter filename after timestamp:" --entry --width=$width)

timestamp=$(exiftool -CreateDate -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
newbasename="$timestamp"_"$filename"

mv "$originalname" "$newbasename.jpg"
[ -e "$basename.RW2" ] && mv "$basename.RW2" "$newbasename.RW2"
[ -e "$basename.RW2.xmp" ] && sed -i -s "s/$basename.RW2/$newbasename.RW2/" "$basename.RW2.xmp"
[ -e "$basename.RW2.xmp" ] && mv "$basename.RW2.xmp" "$newbasename.RW2.xmp"
