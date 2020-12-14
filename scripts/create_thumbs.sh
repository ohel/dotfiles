#!/bin/bash
# Create thumbnails of given size ($1) of given media files ($2).
# For use in Markdown documents (blogs) etc.
# MP4 video thumbnails are also supported using ffmpeg.

if [[ "$#" -lt 1 ]] || ! [[ $1 =~ ^[0-9]+$ ]]
then
    echo "Give the maximum thumbnail size as a first parameter (\$1 x \$1 pixels)."
    echo "A nice example size for blog articles is 450."
    exit 1
fi
size=$1

[ "$#" -lt 2 ] && echo "Give the names of the pictures as parameters after the size parameter."

shift

while [ -n "$1" ]
do
    echo ""

    if [ "$(echo $1 | grep thumb_.*\.jpg)" ]
    then
        echo "Skipped creating thumbnail for $1"
        shift
        continue
    fi

    filename_thumb=thumb_"${1%.*}".jpg
    if [ -e "$filename_thumb" ]
    then
        echo "The thumbnail $filename_thumb already exists."
        echo "Skipped creating thumbnail for $1"
        shift
        continue
    fi

    inputfile="$1"
    videotempfile=""
    extension="${1##*.}"
    if [ "$extension" == "mp4" ] && [ "$(which ffmpeg 2>/dev/null)" ]
    then
        videotempfile=$(mktemp --suffix=.png)
        ffmpeg -i "$1" -vf thumbnail -frames:v 1 -y $videotempfile &> /dev/null
        inputfile=$videotempfile
    fi
    convert "$inputfile" -resize "$size"x"$size" -strip -quality 75 "$filename_thumb"

    [ "$videotempfile" ] && [ -e "$videotempfile" ] && rm "$videotempfile"

    echo "Created thumbnail $filename_thumb"
    echo "Copy-paste for a Markdown blog post:"
    echo "[![Alt text]($filename_thumb \"Optional image caption.\")]($1)"

    shift

done
