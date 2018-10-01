#!/bin/sh
# Given an input video, compress it to a H.264 video.
# Audio must be PCM (so input video must probably be AVI).
# Audio is resampled to 44.1 kHz.
# Needs ffmpeg with fdkaac libs, with sox (for normalizing) and fdkaac encoders.
# Give video quality (CRF) as $2, default is 25.
# Give audio quality (0-5 * 48 kbps) as $3, default is 2. 0 means no audio.
# Give resolution ("720p" or "1080p" as $4), default is 720p.

input=$1
vquality=${2:-25}
aquality=${3:-2}
resolution=${4:-720p}

if [ ! "$input" ]
then
    echo Define an input video file.
    echo "\$1 input video"
    echo "\$2 video quality (1-100)"
    echo "\$3 audio quality (1-5, 0 = no audio)"
    echo "\$4 video resolution (720p, 1080p)"
    exit 1
fi

if [ $vquality -lt 1 ] || [ $vquality -gt 100 ]
then
    echo Video quality must be between 1 and 100, given as integer.
    exit 1
fi

if [ $aquality -lt 0 ] || [ $aquality -gt 5 ]
then
    echo Audio quality must be between 0 and 5, given as integer.
    exit 1
fi

if [ "$resolution" = "1080p" ]
then
    res=1920
else
    res=1280
fi

tmpfile=~/.cache/out

if [ $aquality -gt 0 ]
then
    echo Extracting audio...
    ffmpeg -loglevel error -acodec pcm_s16le -i $input -c copy -map 0:a:0 $tmpfile.wav

    if [ "$(which sox 2>/dev/null)" ]
    then
        echo Normalizing audio...
        sox -q $tmpfile.wav -r 44.1k --norm=-3 $tmpfile.normalized.wav
    else
        mv $tmpfile.wav $tmpfile.normalized.wav
    fi

    echo Compressing audio...
    if [ "$(which fdkaac 2>/dev/null)" ]
    then
        bitrate=$(echo 48000*$aquality | bc)
        fdkaac -S -b $bitrate $tmpfile.normalized.wav -o $tmpfile.m4a
    else
        ffmpeg -loglevel error -i $tmpfile.normalized.wav -codec:a libfdk_aac -aq 0.0$aquality -ar 44100 $tmpfile.m4a
    fi
fi

echo Compressing video...
ffmpeg -loglevel error -i $input -vcodec libx264 -crf $vquality -an -vf scale=$res:-1 "$input"_video.mp4

if [ $aquality -gt 0 ]
then
    echo Muxing video...
    ffmpeg -loglevel error -i "$input"_video.mp4 -i $tmpfile.m4a -c copy -map 0:v:0 -map 1:a:0 $input.mp4
else
    mv "$input"_video.mp4 $input.mp4
fi
rm $tmpfile.normalized.wav $tmpfile.wav $tmpfile.m4a "$input"_video.mp4 2>/dev/null

echo Done.
