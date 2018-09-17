#!/bin/sh
# Download YouTube videos using youtube-dl in a well compressed, good-quality format.

audio_fid=171 # vorbis@128k
video_fid=247 # vp9, 720p

[ "$#" -ne 1 ] && exit 1

destination=$(youtube-dl -f $audio_fid -o "%(title)s" $1 | grep Destination | cut -f 2 -d ':' | sed -e 's/^[[:space:]]*//')
youtube-dl -f $video_fid -o "$destination.video" $1

ffmpeg -i "$destination.video" -i "$destination" -c copy -map 0:v:0 -map 1:a:0 "$destination.mkv"
rm "$destination"
rm "$destination.video"
