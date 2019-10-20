#!/bin/sh
# Lock screen using i3lock.

lockscreensdir=~/.themes/lockscreens
lockscreen=~/.themes/lockscreen.png

if [ -d $lockscreensdir ]
then
    count=$(ls -1 $lockscreensdir/*.png | wc -l)
    index=$(shuf -i 1-$count -n 1)
    lockscreen=$(ls -1 $lockscreensdir/*.png | head -n $index | tail -n 1)
fi

i3lock -t -e -i $lockscreen
