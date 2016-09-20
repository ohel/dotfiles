#!/bin/bash

# The AAC encoder in Avidemux is buggy and adds a strange sound to the beginning of each track.
# Given an .avi video (saved in Avidemux) with PCM audio, this script will compress the audio
# using AAC and mux the results in a single .mp4 file.

# Audio is resampled to 44.1 kHz and bitrate is given via an optional second parameter.
# Needs ffmpeg, sox and fdkaac to work.

input=$1
bitrate=${2:-96000}

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
fdkaac -S -b $bitrate $tmpfile.normalized.wav -o $tmpfile.m4a
echo Muxing with video...
ffmpeg -loglevel fatal -i $input -i $tmpfile.m4a -c copy -map 0:v:0 -map 1:a:0 $(basename -s .avi $input).mp4
rm $tmpfile.normalized.wav $tmpfile.wav $tmpfile.m4a
echo Done.

