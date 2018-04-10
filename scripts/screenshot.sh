#!/bin/sh
# Take a screen cap with running index postfix.
indexfile=~/.cache/screenshot_index
if [ ! -e $indexfile ]; then
    echo 1 > $indexfile
fi
index=$(cat $indexfile)
echo $(expr $index + 1) > $indexfile

if [ "$#" = 1 ]; then
    sleep $1
fi
import -window root ~/screenshot$index.png
