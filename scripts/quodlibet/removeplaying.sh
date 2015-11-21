#!/bin/sh
qlexe=/opt/programs/quodlibet/quodlibet.py
playing=$($qlexe --status | cut -f 1 -d ' ' | head -n 1)
if [ ! "$playing"="playing" ]; then
    echo "Quod Libet is not playing any song."
    exit
fi
filename=$(cat ~/.quodlibet/current | grep ~filename | cut -f 2 -d '=')
$qlexe --next
mkdir -p /tmp/qlremoved
mv "$filename" /tmp/qlremoved

