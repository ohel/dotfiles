#!/usr/bin/sh
# Encode all flac files in subdirectories to ogg vorbis in batches of $batchsize. This is far from perfect parallelization, but good enough.

oggdir=${1:-ogg}
overwrite=${2:-0}
batchsize=${3:-4}

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
