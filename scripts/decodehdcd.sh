#!/bin/sh
# Decode a HDCD signal from flac files a[0-9].flac etc. to b[0-9].flac.
# Uses the Windows application eac3to and Wine to run it.

numfiles=$1
filenumber=0
while [ $filenumber -lt $numfiles ]
do
    filenumber=`expr $filenumber + 1`
    if [ $filenumber -lt 10 ]
    then
        wine eac3to.exe a0$filenumber.flac b0$filenumber.flac -decodeHdcd
        rm "b0$filenumber - Log.txt"
    else
        wine eac3to.exe a$filenumber.flac b$filenumber.flac -decodeHdcd
        rm "b$filenumber - Log.txt"
    fi
done
