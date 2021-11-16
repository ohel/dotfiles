#!/bin/sh
# Given an input video with AAC audio, resample to 44.1 kHz and normalize its audio.
# Needs ffmpeg with fdkaac libs, with sox (for normalizing) and fdkaac encoders.
# This is useful because encoding audio in Avidemux results in errors in the beginning of audio.

input=$1
aquality=${2:-3}

if [ ! "$input" ]
then
    echo Define an input video file.
    echo "\$1 input video"
    echo "\$2 audio quality (1-5, 0 = no audio)"
    exit 1
fi

if [ $aquality -lt 1 ] || [ $aquality -gt 5 ]
then
    echo Audio quality must be between 1 and 5, given as integer.
    exit 1
fi

tmpfile=~/.cache/out

echo Extracting audio...
ffmpeg -loglevel error -i "$input" -map 0:a:0 $tmpfile.wav

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

echo Muxing video...
ffmpeg -loglevel error -i "$input" -i $tmpfile.m4a -c copy -map 0:v:0 -map 1:a:0 new_"$input"
rm $tmpfile.normalized.wav $tmpfile.wav $tmpfile.m4a 2>/dev/null

echo Done.
