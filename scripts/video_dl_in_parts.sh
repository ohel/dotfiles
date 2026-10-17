#!/usr/bin/bash
# Download videos in parts and concatenate parts to a single continuous video.
# Copy the URL from a web browser's network tab; any segment is fine.
# When downloaded segment contains just plain text, it's taken as the last segment.
# First parameter may also be a m3u8 playlist, for non-continuous indices for example.
#
# Parameters:
# $1: URL (use double quotes) or playlist file
# $2: playlist URL prefix if playlist file given as $1; is automatically cut on segment cue
# $3: segment cue, defaults to "seg-"; a growing segment index should follow
# $4: extension; defaults to "mp4"
# $5: start index for URLs; defaults to 1
# $6: max index for URLS if not automatically detected; defaults to 1000
# $7: stop on ASCII file found if URL; 1 for yes, 0 for no, defaults to 1

use_url=0 && [ "$(echo "$1" | grep "^http")" ] && use_url=1
[ $use_url -eq 0 ] && playlist_file="$1" && shift

seg_cue=${2:-seg-}
extension=${3:-mp4}
if [ $use_url -eq 1 ]
then
    url_part_1=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\1$seg_cue/")
    url_part_2=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\2/")
    start_index=${4:-1}
    max_index=${5:-1000}
    stop_on_ascii=${6:-1}
else
    url_part_1=$(echo "$1" | sed "s/\(.*\)$seg_cue[0-9]*\(.*\)/\1/")
    playlist=($(grep "^$seg_cue" "$playlist_file"))
    start_index=0
    max_index=${#playlist[@]}
    stop_on_ascii=0
fi

tmp_dir=$(mktemp -d)

echo "Enter output filename without extension [complete]:"
read completed
[ ! "$completed" ] && completed="complete"

echo "Enter referer header []:"
printf https://www.
read referer
[ "$referer" ] && referer="https://www.$referer"
user_agent="user-agent: Linux"

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
    filesize=0
    while [ $filesize -le 1 ]
    do
        if [ $use_url -eq 1 ]
        then
            segment_url=$url_part_1$current_index$url_part_2
        else
            segment_url=$url_part_1${playlist[$current_index]}
        fi

        [ "$referer" ] && curl $segment_url -H "referer: $referer" -H "$user_agent" > $tmp_dir/$filename
        [ ! "$referer" ] && curl $segment_url -H "$user_agent" > $tmp_dir/$filename

        filesize=$(stat -c %s $tmp_dir/$filename)
        [ $filesize -le 1 ] && echo "Downloading $current_index again, probably errored..."
    done
    current_index=$(expr $current_index + 1)

    if [ "$(file $tmp_dir/$filename | grep "ASCII text")" ]
    then
        if [ $stop_on_ascii -eq 1 ] || [ "$(cat $tmp_dir/$filename)" = "Not Found" ]
        then
            rm $tmp_dir/$filename
            break
        fi
    fi
done

echo Concatenating segments...
ffmpeg -f concat -safe 0 -i <(for f in $tmp_dir/seg_*.$extension; do echo "file '$f'"; done) -c copy "$completed".$extension

if [ ! -e complete.$extension ]
then
    echo Error concatenating files using ffmpeg, using cat instead.
    cat $tmp_dir/seg_*.$extension >> "$completed".$extension
fi

rm -rf $tmp_dir
