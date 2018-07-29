#!/bin/sh
# Toggle alternative background when using xfdesktop.

checkfile=~/.cache/backgroundchanged
if [ -f $checkfile ]
then
    ln -sf ~/.themes/background.png ~/.themes/background
    exec ~/.scripts/launchers/conky.sh &
    rm $checkfile
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    killall conky
    touch $checkfile
fi

xfdesktop --reload &
