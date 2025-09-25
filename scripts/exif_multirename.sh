#!/usr/bin/sh
# Given filenames (use as appearance condition in file managers such as Thunar):
# *.jpg;*.JPG;*.RW2;*.RW2.xmp;*.CR3;*.CR3.xmp;*.ORF;*.ORF.xmp;*.mp4;*.MP4;*.mov;*.MOV;*.dng
# rename matching files with those extensions as:
# YYYY-mm-dd_HH.MM.SS_<desc>.<ext>, where <desc> is an optional description from zenity input and <ext> the original extension.
# In case of image filees, if a similarly named file but with other extension (i.e. RAW format + JPG format pair) exists, they are renamed too,
# and the file name updated into the xmp file contents if a corresponding xmp file exists.
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
    echo "$inputname" | grep -oi "\.jpg$"             && basename=$(basename "$inputname" | sed "s/\.jpg$\|\.JPG$//")      && targetext="jpg"
    echo "$inputname" | grep -o "\.RW2$\|\.RW2\.xmp$" && basename=$(basename "$inputname" | sed "s/\.RW2$\|\.RW2\.xmp$//") && targetext="RW2"
    echo "$inputname" | grep -o "\.CR3$\|\.CR3\.xmp$" && basename=$(basename "$inputname" | sed "s/\.CR3$\|\.CR3\.xmp$//") && targetext="CR3"
    echo "$inputname" | grep -o "\.ORF$\|\.ORF\.xmp$" && basename=$(basename "$inputname" | sed "s/\.ORF$\|\.ORF\.xmp$//") && targetext="ORF"
    echo "$inputname" | grep -oi "\.mp4$"             && basename=$(basename "$inputname" | sed "s/\.mp4$\|\.MP4$//")      && targetext="mp4"
    echo "$inputname" | grep -oi "\.mov$"             && basename=$(basename "$inputname" | sed "s/\.mov$\|\.MOV$//")      && targetext="mov"
    echo "$inputname" | grep -o  "\.dng$"             && basename=$(basename "$inputname" | sed "s/\.dng$//")              && targetext="dng"

    originalname=""
    [ "$targetext" = "jpg" ] && [ -e "$basename.jpg" ] && originalname="$basename.jpg"
    [ "$targetext" = "jpg" ] && [ -e "$basename.JPG" ] && originalname="$basename.JPG"
    [ "$targetext" = "RW2" ] && [ -e "$basename.RW2" ] && originalname="$basename.RW2"
    [ "$targetext" = "CR3" ] && [ -e "$basename.CR3" ] && originalname="$basename.CR3"
    [ "$targetext" = "ORF" ] && [ -e "$basename.ORF" ] && originalname="$basename.ORF"
    [ "$targetext" = "mp4" ] && [ -e "$basename.mp4" ] && originalname="$basename.mp4"
    [ "$targetext" = "mp4" ] && [ -e "$basename.MP4" ] && originalname="$basename.MP4"
    [ "$targetext" = "mov" ] && [ -e "$basename.mov" ] && originalname="$basename.mov"
    [ "$targetext" = "mov" ] && [ -e "$basename.MOV" ] && originalname="$basename.MOV"
    [ "$targetext" = "dng" ] && [ -e "$basename.dng" ] && originalname="$basename.dng"

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

    # For video files, e.g. Samsung S23 and S25 don't store the timezone offset information anywhere, but it writes an author tag.
    # Recognize these cases and use the filename as timestamp if possible.
    author=$(exiftool -Author "$originalname" | cut -f 2 -d ':' | tr -d ' ')
    timestamp=""
    if [ "$author" = "GalaxyS23" ] || [ "$author" = "GalaxyS25" ]
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

    # Video files.
    [ "$targetext" = "mp4" ] && mv "$originalname" "$newbasename$postfix.mp4" && continue
    [ "$targetext" = "mov" ] && mv "$originalname" "$newbasename$postfix.mov" && continue

    # JPG + RAW pairs.
    [ "$targetext" = "jpg" ] && mv "$originalname" "$newbasename$postfix.jpg"

    [ -e "$basename.RW2" ] && mv "$basename.RW2" "$newbasename$postfix.RW2"
    [ -e "$basename.RW2.xmp" ] && sed -i -s "s/$basename.RW2/$newbasename$postfix.RW2/" "$basename.RW2.xmp"
    [ -e "$basename.RW2.xmp" ] && mv "$basename.RW2.xmp" "$newbasename$postfix.RW2.xmp"

    [ -e "$basename.CR3" ] && mv "$basename.CR3" "$newbasename$postfix.CR3"
    [ -e "$basename.CR3.xmp" ] && sed -i -s "s/$basename.CR3/$newbasename$postfix.CR3/" "$basename.CR3.xmp"
    [ -e "$basename.CR3.xmp" ] && mv "$basename.CR3.xmp" "$newbasename$postfix.CR3.xmp"

    [ -e "$basename.ORF" ] && mv "$basename.ORF" "$newbasename$postfix.ORF"
    [ -e "$basename.ORF.xmp" ] && sed -i -s "s/$basename.ORF/$newbasename$postfix.ORF/" "$basename.ORF.xmp"
    [ -e "$basename.ORF.xmp" ] && mv "$basename.ORF.xmp" "$newbasename$postfix.ORF.xmp"

    [ -e "$basename.dng" ] && mv "$basename.dng" "$newbasename$postfix.dng"
    [ -e "$basename.dng.xmp" ] && sed -i -s "s/$basename.dng/$newbasename$postfix.dng/" "$basename.dng.xmp"
    [ -e "$basename.dng.xmp" ] && mv "$basename.dng.xmp" "$newbasename$postfix.dng.xmp"
done
