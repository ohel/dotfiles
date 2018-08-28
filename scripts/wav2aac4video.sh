#!/bin/bash

# The AAC encoder in Avidemux is buggy and adds a strange sound to the beginning of each track.
# Given an .avi video (saved in Avidemux) with PCM audio, this script will compress the audio
# using AAC and mux the results in a single .mp4 file.

# Audio is resampled to 44.1 kHz and bitrate is given via an optional second parameter.
# Needs ffmpeg with fdkaac libs, with sox (for normalizing) and fdkaac encoders optionally.

input=$1
quality=${2:-2}

if [[ $quality -lt 1 || $quality -gt 5 ]]
then
    echo "Audio quality must be between 1 and 5, given as integer."
    exit 1
fi

if test "X$input" == "X"
then
    echo "Define a .avi file."
    exit 1
fi
if test "$(basename -s .avi $input)" == "$input"
then
    echo "Input video must have a .avi suffix."
    exit 1
fi

tmpfile=~/.cache/out

echo Extracting audio...
ffmpeg -loglevel error -acodec pcm_s16le -i $input -c copy -map 0:a:0 $tmpfile.wav

if test "X$(which sox 2>/dev/null)" != "X"
then
    echo Normalizing audio...
    sox -q $tmpfile.wav -r 44.1k --norm=-3 $tmpfile.normalized.wav
else
    mv $tmpfile.wav $tmpfile.normalized.wav
fi

echo Compressing audio...
if test "X$(which fdkaac 2>/dev/null)" != "X"
then
    bitrate=$(echo 48000*$quality | bc)
    fdkaac -S -b $bitrate $tmpfile.normalized.wav -o $tmpfile.m4a
else
    ffmpeg -loglevel error -i $tmpfile.normalized.wav -codec:a libfdk_aac -aq 0.0$quality -ar 44100 $tmpfile.m4a
fi

echo Muxing with video...
ffmpeg -loglevel error -i $input -i $tmpfile.m4a -c copy -map 0:v:0 -map 1:a:0 $(basename -s .avi $input).mp4
rm $tmpfile.normalized.wav $tmpfile.wav $tmpfile.m4a 2>/dev/null
echo Done.

