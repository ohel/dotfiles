#!/usr/bin/sh
# Given two image files, add tags from one to another and rename the files.
# This is done by calling other EXIF scripts. A note is added to EXIF source filename.
# The source for copying is based on which image has the ISO speed rating EXIF info.
#
# For example, if you have the original file with EXIF data image.JPG from your digital camera,
# and image.jpg exported from an intermediate format (such as image.exr) without EXIF data,
# call this script for image.JPG and image.jpg.

scriptsdir=$(dirname "$(readlink -f "$0")")

[ "$3" != "" ] && echo "Too many parameters." && exit 1
[ ! -e "$1" ] && echo "File $1 doesn't exist." && exit 1
[ ! -e "$2" ] && echo "File $2 doesn't exist." && exit 1

source_file=""
[ "$(exiftool -ISO $1)" ] && source_file="$1" && dest_file="$2"
[ "$(exiftool -ISO $2)" ] && source_file="$2" && dest_file="$1"
[ ! "$source_file" ] && echo "ISO EXIF data not found in either file." && exit 1

"$scriptsdir/exif_copy_tags.sh" "$source_file" "$dest_file" add

mv "$source_file" "$source_file"_exif_source
"$scriptsdir/exif_multirename.sh" "$dest_file"
