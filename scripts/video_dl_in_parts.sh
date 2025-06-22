#!/usr/bin/bash
# Download videos in parts and concatenate parts to a single continuous video.
# Copy the URL from a web browser's network tab; any segment is fine.
# When downloaded segment contains just plain text, it's taken as the last segment.
#
# Parameters:
# $1: URL (use double quotes)
# $2: segment cue, defaults to "seg-"; a growing segment index should follow
# $3: start index; defaults to 1
# $4: max index, if not automatically detected; defaults to 1000
# $5: extension; defaults to "mp4"

seg_cue=${2:-seg-}
url_part_1=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\1$seg_cue/")
url_part_2=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\2/")
start_index=${3:-1}
max_index=${4:-1000}
extension=${5:-mp4}

tmp_dir=$(mktemp -d)

echo "Enter output filename without extension [complete]:"
read completed
[ ! "$completed" ] && completed="complete"

current_index=$start_index
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
ffmpeg -f concat -safe 0 -i <(for f in $tmp_dir/seg_*.$extension; do echo "file '$f'"; done) -c copy "$completed".$extension

if [ ! -e complete.$extension ]
then
    echo Error concatenating files using ffmpeg, using cat instead.
    cat $tmp_dir/seg_*.$extension >> "$completed".$extension
fi

rm $tmp_dir/seg_*.$extension
