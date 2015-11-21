#!/bin/bash
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

