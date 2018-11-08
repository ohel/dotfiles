#!/bin/sh
# Download YouTube videos using youtube-dl in a well compressed, good-quality format.

audio_fid=171 # vorbis@128k
video_fid=136 # avc1.4d401f, 720p, 30fps
hq_audio_fid=251 # opus@160k
hq_video_30_fid=137 # avc1.640028, 1080p, 30fps
hq_video_60_fid=299 # avc1.64002a, 1080p, 60fps

[ "$#" -eq 0 ] && echo "No URL given." && exit 1

hq=0
[ "$2" = "hq" ] && hq=1

formats=$(youtube-dl -F "$1" | grep -o "^[0-9]\{1,3\}" | tr "\n" ",")

if [ $hq = 1 ]
then
    [ $(echo $formats | grep $hq_video_30_fid, ) ] && video_fid=$hq_video_30_fid
    [ $(echo $formats | grep $hq_video_60_fid, ) ] && video_fid=$hq_video_60_fid
    [ $(echo $formats | grep $hq_audio_fid, ) ] && audio_fid=$hq_audio_fid
fi

destination=$(youtube-dl -f $audio_fid -o "%(title)s" "$1" | grep Destination | cut -f 2 -d ':' | sed -e 's/^[[:space:]]*//')
youtube-dl -f $video_fid -o "$destination.video" "$1"

ffmpeg -i "$destination.video" -i "$destination" -c copy -map 0:v:0 -map 1:a:0 "$destination.mkv"
rm "$destination"
rm "$destination.video"
