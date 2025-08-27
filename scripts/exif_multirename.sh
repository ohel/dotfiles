#!/usr/bin/sh
# Given filenames ending in .jpg/.JPG, .RW2/.RW2.xmp, or .CR3/.CR3.xmp, rename matching files with those extensions as:
# YYYY-mm-dd_HH.MM.SS_<desc>.<ext>, where <desc> is an optional description from zenity input and <ext> the original extension.
# If a similarly named file but with other extension exists, they are renamed too,
# and the file name updated into the xmp file contents if an xmp file exists.
#
# Alternatively, besides jpg, RW2, and CR3, mp4 (MP4) or mov (MOV) files may be given as input directly.
#
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
    echo "$inputname" | grep -oi "\.jpg$" && basename=$(basename "$inputname" | sed "s/\.jpg$\|\.JPG$//") && targetext="jpg"
    echo "$inputname" | grep -o "\.RW2$\|\.RW2\.xmp$" && basename=$(basename "$inputname" | sed "s/\.RW2$\|\.RW2\.xmp$//") && targetext="RW2"
    echo "$inputname" | grep -o "\.CR3$\|\.CR3\.xmp$" && basename=$(basename "$inputname" | sed "s/\.CR3$\|\.CR3\.xmp$//") && targetext="CR3"
    echo "$inputname" | grep -oi "\.mp4$" && basename=$(basename "$inputname" | sed "s/\.mp4$\|\.MP4$//") && targetext="mp4"
    echo "$inputname" | grep -oi "\.mov$" && basename=$(basename "$inputname" | sed "s/\.mov$\|\.MOV$//") && targetext="mov"

    originalname=""
    [ "$targetext" = "jpg" ] && [ -e "$basename.jpg" ] && originalname="$basename.jpg"
    [ "$targetext" = "jpg" ] && [ -e "$basename.JPG" ] && originalname="$basename.JPG"
    [ "$targetext" = "RW2" ] && [ -e "$basename.RW2" ] && originalname="$basename.RW2"
    [ "$targetext" = "CR3" ] && [ -e "$basename.CR3" ] && originalname="$basename.CR3"
    [ "$targetext" = "mp4" ] && [ -e "$basename.mp4" ] && originalname="$basename.mp4"
    [ "$targetext" = "mp4" ] && [ -e "$basename.MP4" ] && originalname="$basename.MP4"
    [ "$targetext" = "mov" ] && [ -e "$basename.mov" ] && originalname="$basename.mov"
    [ "$targetext" = "mov" ] && [ -e "$basename.MOV" ] && originalname="$basename.MOV"

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

    # For video files, Samsung S23 doesn't store the timezone offset information anywhere, but it writes an author tag.
    # Recognize these cases and use the filename as timestamp if possible.
    author=$(exiftool -Author "$originalname" | cut -f 2 -d ':' | tr -d ' ')
    timestamp=""
    if [ "$author" = "GalaxyS23" ]
    then
        timestamp=$(echo "$originalname" | grep -o "^[0-9]\{4,\}-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]")
        raw_timestamp=$(echo "$originalname" | grep -o "^[0-9]\{8,\}_[0-9]\{6,\}")
        [ "$raw_timestamp" ] && timestamp=$(echo $raw_timestamp | sed "s/\([0-9]\{4,\}\)\([0-9][0-9]\)\([0-9][0-9]\)_\([0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)/\1-\2-\3_\4.\5.\6/")
    fi

    if [ ! "$timestamp" ]
    then
        # Prefer Date/Time Original if found as it is usually more correct.
        # Note that especially for video files, the create timestamp might be when the video ends, not when it starts.
        timestamp=$(exiftool -DateTimeOriginal -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
        [ ! "$timestamp" ] && timestamp=$(exiftool -CreateDate -d %Y-%m-%d_%H.%M.%S "$originalname" | cut -f 2 -d ':' | tr -d ' ')
        [ ! "$timestamp" ] && echo "No timestamp found in EXIF data, continuing batch." && continue
    fi

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

    [ "$targetext" = "mp4" ] && mv "$originalname" "$newbasename$postfix.mp4" && continue
    [ "$targetext" = "mov" ] && mv "$originalname" "$newbasename$postfix.mov" && continue

    [ "$targetext" = "jpg" ] && mv "$originalname" "$newbasename$postfix.jpg"

    [ -e "$basename.RW2" ] && mv "$basename.RW2" "$newbasename$postfix.RW2"
    [ -e "$basename.RW2.xmp" ] && sed -i -s "s/$basename.RW2/$newbasename$postfix.RW2/" "$basename.RW2.xmp"
    [ -e "$basename.RW2.xmp" ] && mv "$basename.RW2.xmp" "$newbasename$postfix.RW2.xmp"

    [ -e "$basename.CR3" ] && mv "$basename.CR3" "$newbasename$postfix.CR3"
    [ -e "$basename.CR3.xmp" ] && sed -i -s "s/$basename.CR3/$newbasename$postfix.CR3/" "$basename.CR3.xmp"
    [ -e "$basename.CR3.xmp" ] && mv "$basename.CR3.xmp" "$newbasename$postfix.CR3.xmp"
done
