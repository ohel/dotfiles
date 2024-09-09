#!/usr/bin/sh
# Given an input video $1, compress it to a H.264 video with reasonable quality.
# Quality (CRF) can be given as $2.
# A factor in $3 can be given for scaling video size (e.g. 0.5 for 4K -> 1080p scaling).
# If $4 = "sdr" then the output will be 8bit in bt709 color primaries.
# If $5 = "265" then the output will be encoded with libx265 instead of libx264.
# Audio is left as is.

input="$1"
vquality=${2:-26}

[ ! "$input" ] && echo "No input video." && exit 1

[ "$3" ] && scale="scale=iw*$3:ih*$3"
[ "$4" = "sdr" ] && convert="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p"
[ "$scale" ] && [ "$convert" ] && scale="$scale,"
vf="$scale$convert" && [ "$vf" ] && vf="-vf $vf"
codec="libx264" && [ "$5" = "265" ] && codec="libx265"

echo Compressing video...
ffmpeg -loglevel error -i "$input" -vcodec $codec -crf $vquality $vf "$(basename -s .mp4 "$input")"_re.mp4

echo Done.
