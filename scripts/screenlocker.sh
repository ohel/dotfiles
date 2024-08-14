#!/usr/bin/sh
# Lock screen using i3lock.
# Randomizes a locksreen image from $imagesdir or uses $image if directory doesn't exist.
# If ImageMagick's convert exists, uses it to resize and feed raw image to i3lock.
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

if [ "$resolution" ] && [ "$(which convert 2>/dev/null)" ]
then
    size=$(echo $resolution | cut -f 1 -d 'x')
    convert -resize "$size"x"$size" -gravity center -crop $resolution+0+0 $image RGB:- | i3lock -e --raw $resolution:rgb -i /dev/stdin
else
    i3lock -t -e -i $image
fi

# Blank screen right after. The sleep is so that using hotkeys for script don't wake up the screen immediately.
[ -e ~/.config/blank_screen ] && sleep 0.1 && xset s activate
