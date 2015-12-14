#!/bin/bash
# Encode all flac files in subdirectories to ogg vorbis in batches of $batchsize. This is far from perfect parallelization, but good enough.

batchsize=4

mkdir -p ogg

flacs=$(find ./ -iname "*.flac")
batchindex=0
for flacfile in $flacs
do
    echo Encoding $flacfile...
    filebase=$(echo $flacfile | sed s/\.flac$//)
    batchindex=$((($batchindex + 1) % 4))

    oggenc -Q -q 7 -o ogg/$filebase.ogg $filebase.flac &

    if [ $batchindex -eq 0 ]; then wait; fi
done
wait
echo "Done."
