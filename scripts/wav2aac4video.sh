#!/bin/bash

# First save the video as .avi in Avidemux, with PCM audio.

input=$1
if test "X$input" == "X"
then
    echo "Define a .avi file."
    exit
fi
if test "$(basename -s .avi $input)" == "$input"
then
    echo "Input video must have a .avi suffix."
    exit
fi

tmpfile=/dev/shm/out

echo Extracting audio...
ffmpeg -loglevel fatal -i $input -c copy -map 0:a:0 $tmpfile.wav
echo Normalizing audio...
sox -q $tmpfile.wav -r 44.1k --norm=-3 $tmpfile.normalized.wav
echo Compressing audio...
fdkaac -S -b 96000 $tmpfile.normalized.wav -o $tmpfile.m4a
echo Muxing with video...
ffmpeg -loglevel fatal -i $input -i $tmpfile.m4a -c copy -map 0:v:0 -map 1:a:0 $(basename -s .avi $input).mp4
rm $tmpfile.normalized.wav $tmpfile.wav $tmpfile.m4a
echo Done.

