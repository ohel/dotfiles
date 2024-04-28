#!/usr/bin/sh
# Given an input video $1, compress it to a H.264 video with reasonable quality.
# Audio is left as is.
# Quality can be given as $2.
# A factor in $3 can be given for scaling video size (e.g. 0.5 for 4K -> 1080p scaling).

input="$1"
vquality=${2:-30}
scale=$3

[ ! "$input" ] && echo "No input video." && exit 1

[ "$scale" ] && scale="-vf scale=iw*$scale:ih*$scale"

echo Compressing video...
ffmpeg -loglevel error -i "$input" -vcodec libx264 -crf $vquality $scale "$(basename -s .mp4 "$input")"_re.mp4

echo Done.
