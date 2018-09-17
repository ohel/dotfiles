#!/bin/sh
# Take a screen cap with running index postfix.

count=$(expr 1 + $(ls ~/screenshot*.png 2>/dev/null | grep "screenshot[0-9]*.png" | wc -l))

[ "$#" = 1 ] && sleep $1

while [ -e ~/screenshot$count.png ]
do
    count=$(expr $count + 1)
done

import -window root ~/screenshot$count.png
