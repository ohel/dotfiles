#!/bin/bash
# Create thumbnails of given size ($1) of given pictures. For use in Markdown documents (blogs) etc.

if [[ "$#" -lt 1 ]] || ! [[ $1 =~ ^[0-9]+$ ]]
then
    echo "Give the maximum thumbnail size as a first parameter (\$1 x \$1 pixels)."
    echo "A nice example size for blog articles is 450."
    exit
fi
size=$1

if [ "$#" -lt 2 ]
then
    echo "Give the names of the pictures as parameters after the size parameter."
fi

shift

while [ -n "$1" ]
do

    filename_thumb=thumb_"${1%.*}".jpg

    if [ -e "$filename_thumb" ]
    then
        echo "Error: the picture $filename_thumb exists. Move it away."
        shift
        continue
    fi

    convert "$1" -resize "$size"x"$size" -strip -quality 75 "$filename_thumb"

    echo "Created thumbnail: $filename_thumb"
    echo "Copy-paste for the blog:"
    echo "[![Alt text]($filename_thumb \"Optional image caption.\")]($1)"
    echo ""

    shift

done
