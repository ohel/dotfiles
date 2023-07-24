#!/bin/sh
# Download videos in parts and concatenate parts to a single continuous video.
# Copy the URL from a web browser's network tab; any segment is fine.
# When downloaded segment contains just plain text, it's taken as the last segment.
#
# Parameters:
# $1: URL (use double quotes)
# $2: segment cue, defaults to "seg-"; a growing segment index should follow
# $3: max index, if not automatically detected; defaults to 1000
# $4: extension; defaults to "mp4"

seg_cue=${2:-seg-}
url_part_1=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\1$seg_cue/")
url_part_2=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\2/")
max_index=${3:-1000}
extension=${4:-mp4}

tmp_dir=$(mktemp -d)

current_index=1
while [ $current_index -le $max_index ]
do
    if [ $current_index -lt 10 ]
    then
        filename="seg_00$current_index.$extension"
    elif [ $current_index -lt 100 ]
    then
        filename="seg_0$current_index.$extension"
    else
        filename="seg_$current_index.$extension"
    fi

    echo "Downloading segment $current_index..."
    curl $url_part_1$current_index$url_part_2 > $tmp_dir/$filename
    current_index=$(expr $current_index + 1)
    if [ "$(file $tmp_dir/$filename | grep "ASCII text")" ]
    then
        rm $tmp_dir/$filename
        break
    fi
done

echo Concatenating segments...
ls $tmp_dir/seg_*.$extension | while read line; do echo file \'$line\'; done | ffmpeg -loglevel warning -protocol_whitelist file,pipe -f concat -safe 0 -i - -c copy complete.$extension

if [ ! -e complete.$extension ]
then
    echo Error concatenating files using ffmpeg, using cat instead.
    cat $tmp_dir/seg_*.$extension >> complete.$extension
fi

rm $tmp_dir/seg_*.$extension
