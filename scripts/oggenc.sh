#!/bin/bash
# Encode all flac files in subdirectories to ogg vorbis in batches of $batchsize. This is far from perfect parallelization, but good enough.

oggdir=ogg
overwrite=0
batchsize=4
if [ "$#" -gt 0 ]; then oggdir=$1; fi
if [ "$#" -gt 1 ]; then overwrite=$2; fi
if [ "$#" -gt 2 ]; then batchsize=$3; fi

mkdir -p $oggdir

flacs=$(find ./ -iname "*.flac")
batchindex=0
for flacfile in $flacs
do
    filebase=$(echo $flacfile | sed s/\.flac$//)

    if [ ! -e $oggdir/$filebase.ogg ] || [ $overwrite -eq 1 ]
    then
        echo Encoding $flacfile...

        batchindex=$((($batchindex + 1) % $batchsize))
        oggenc -Q -q 7 -o $oggdir/$filebase.ogg $filebase.flac &

        if [ $batchindex -eq 0 ]; then wait; fi
    else
        echo "Skipped existing file: $flacfile.ogg"
    fi
done
wait
echo "Done."
