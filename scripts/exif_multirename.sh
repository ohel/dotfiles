#!/bin/sh
# Given filenames ending in .jpg, .JPG, .RW2 or .RW2.xmp, rename a matching JPEG file as:
# YYYY-mm-dd_HH.MM.SS_<desc>.jpg, where <desc> is an optional description from zenity input.
# If a similarly named .RW2 or .RW2.xmp file exists, they are renamed too, and the file name updated into the .RW2.xmp file contents.
# Alternatively, if no JPEG file exists, RW2 or mp4 (MP4) files may be given as input directly.
# Exiftool is used for reading timestamp metadata.
# If input is multiple files, the _<desc> is omitted from the end of the file name.
# If input is a single file but no new description is given, and a description exists, the old one is used.

[ ! "$1" ] && echo "Missing arguments." && exit 1
[ ! "$(which exiftool 2>/dev/null)" ] && echo "Missing exiftool." && exit 1

# Use this description separator but only if this is a batch run, i.e. more than one file.
separator="_"
[ "$#" -gt 1 ] && separator=""

width=$(echo "$(xrandr | grep -o "current [0-9]*" | cut -f 2 -d ' ') / 4" | bc)

for inputname in "$@"
do
    # Figure out the file extension.
    targetext=""
    basename=$(basename -s .jpg "$inputname")
    [ "$basename" = "$inputname" ] && basename=$(basename -s .JPG "$inputname")
    [ "$basename" != "$inputname" ] && targetext="jpg"
    [ "$basename" = "$inputname" ] && basename=$(basename -s .RW2 "$inputname")
    [ "$basename" = "$inputname" ] && basename=$(basename -s .RW2.xmp "$inputname")
    [ "$basename" != "$inputname" ] && [ ! "$targetext" ] && targetext="RW2"
    [ "$basename" = "$inputname" ] && basename=$(basename -s .mp4 "$inputname")
    [ "$basename" = "$inputname" ] && basename=$(basename -s .MP4 "$inputname")
    [ "$basename" != "$inputname" ] && [ ! "$targetext" ] && targetext="mp4"

    originalname=""
    [ "$targetext" = "jpg" ] && [ -e "$basename.jpg" ] && originalname="$basename.jpg"
    [ "$targetext" = "jpg" ] && [ -e "$basename.JPG" ] && originalname="$basename.JPG"
    [ "$targetext" = "RW2" ] && [ -e "$basename.RW2" ] && originalname="$basename.RW2"
    [ "$targetext" = "mp4" ] && [ -e "$basename.mp4" ] && originalname="$basename.mp4"
    [ "$targetext" = "mp4" ] && [ -e "$basename.MP4" ] && originalname="$basename.MP4"

    if [ ! "$originalname" ]
    then
        echo "File not found or unknown extension: $originalname"
        # Not a batch if separator is defined, error out.
        [ "$separator" ] && exit 1
        echo "File probably already renamed, continuing batch."
        continue
    fi

    desc=""
    if [ "$separator" ]
    then
        [ "$(which zenity 2>/dev/null)" ] && [ "$width" ] && desc=$(zenity --title="New filename" --text="Enter filename after timestamp, leave empty to use current, or cancel for no rename:" --entry --width=$width)
        # Check if user cancelled.
        [ "$?" = 1 ] && exit 1
        # If no description was given, use old description if found after timestamp.
        [ ! "$desc" ] && desc=$(echo $basename | grep "[0-9]\{4\}-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]_.*" | cut -f 3- -d '_')
    fi

    # Prefer Date/Time Original if found as it is usually more correct.
    # Note that especially for video files, the create timestamp might be when the video ends, not when it starts.
    timestamp=$(exiftool -DateTimeOriginal -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
    [ ! "$timestamp" ] && timestamp=$(exiftool -CreateDate -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
    [ ! "$timestamp" ] && echo "No timestamp found in EXIF data, continuing batch." && continue

    # If no description is given, just use the timestamp as the file name.
    newbasename="$timestamp$separator$desc"
    [ ! "$desc" ] && newbasename="$timestamp"

    # Nothing to rename so skip to next file.
    [ "$newbasename.$targetext" = "$originalname" ] && continue

    postfix=""
    if [ -e "$newbasename.$targetext" ]
    then
        index=$(ls -1 "$newbasename"*."$targetext" | wc -l)
        postfix="_$index"
    fi

    [ "$targetext" = "jpg" ] && mv "$originalname" "$newbasename$postfix.jpg"
    [ "$targetext" = "mp4" ] && mv "$originalname" "$newbasename$postfix.mp4"
    [ -e "$basename.RW2" ] && mv "$basename.RW2" "$newbasename$postfix.RW2"
    [ -e "$basename.RW2.xmp" ] && sed -i -s "s/$basename.RW2/$newbasename$postfix.RW2/" "$basename.RW2.xmp"
    [ -e "$basename.RW2.xmp" ] && mv "$basename.RW2.xmp" "$newbasename$postfix.RW2.xmp"
done
