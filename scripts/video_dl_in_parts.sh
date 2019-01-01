#!/bin/bash
# Download videos in parts and concatenate parts to a single continuous video.
# Edit the download URLs and max_index to match the cURL copied from a web browser.

url_part_1=''
url_part_2=''
max_index=500

extension=mp4
current_index=1
while [ $current_index -le $max_index ];
do
    if [ $current_index -lt 10 ]
    then
        filename="frag_00$current_index.$extension"
    elif [ $current_index -lt 100 ]
    then
        filename="frag_0$current_index.$extension"
    else
        filename="frag_$current_index.$extension"
    fi

    echo "Downloading fragment $current_index/$max_index..."
    curl $url_part_1$current_index$url_part_2 > $filename
    current_index=$(expr $current_index + 1)
done

echo Concatenating fragments...
ls frag_*.$extension | while read line; do echo file \'$line\'; done | ffmpeg -loglevel warning -protocol_whitelist file,pipe -f concat -i - -c copy complete.$extension

rm frag_*.$extension
