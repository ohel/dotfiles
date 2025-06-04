#!/usr/bin/sh
# Lock screen using i3lock.
# Randomizes a locksreen image from $imagesdir or uses $image if directory doesn't exist.
# If ImageMagick exists, uses it to resize and feed raw image to i3lock.
# If ~/.config/blank_screen exists, also blanks the screen right after locking.

imagesdir=~/.themes/lockscreens
image=~/.themes/lockscreen.png

# i3lock is already running.
[ "$(ps -e | grep i3lock)" ] && exit 1

if [ -d $imagesdir ]
then
    count=$(ls -1 $imagesdir/*.* | wc -l)
    index=$(shuf -i 1-$count -n 1)
    image=$(ls -1 $imagesdir/*.* | head -n $index | tail -n 1)
fi

# First found screen resolution of form <width>x<height>, e.g. 3840x2160.
resolution=$(xrandr | grep "[0-9.][0-9.]\*" | head -n 1 | grep -o "[0-9]*x[0-9]*")

if [ "$resolution" ] && [ "$(which magick 2>/dev/null)" ]
then
    size=$(echo $resolution | cut -f 1 -d 'x')
    # Sometimes magick segfaults with xautolock for some reason. Seems to happen more often with pipes than temporary files.
    # Hence we kill the magick process if it runs for more than a couple of seconds.
    conflict_pid=$(ps -ef | grep "magick" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
    magick $image -resize "$size"x"$size" -gravity center -crop $resolution+0+0 RGB:- | i3lock -e -t --raw $resolution:rgb -i /dev/stdin
    i3lock -e -t --raw $resolution:rgb -i $tmpfile
else
    conflict_pid="skip"
    i3lock -e -t -i $image
fi

# Blank screen right after. The sleep is so that using hotkeys for script don't wake up the screen immediately.
[ -e ~/.config/blank_screen ] && sleep 0.1 && xset s activate

if [ "$conflict_pid" ]
then
    sleep 2
    pid=$(ps -ef | grep "magick" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
    [ "$pid" ] && kill -9 $pid
fi
