#!/bin/sh
# Remove (move to temporary location) currently playing song in Quod Libet.
# This is useful when searching nice ones from a very large number of songs.

ql=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet.py$")
[ $ql ] && playing=$($ql --status | cut -f 1 -d ' ' | head -n 1)
if [ ! "$playing" = "playing" ]
then
    echo "Quod Libet is not playing any song."
    exit 1
fi
filename=$(cat ~/.quodlibet/current | grep ~filename | cut -f 2 -d '=')
$ql --next
mkdir -p /tmp/qlremoved
mv "$filename" /tmp/qlremoved
