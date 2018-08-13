#!/bin/bash
# Toggle alternative background when using xfdesktop.
# The alternative background kills conky if in use.

checkfile=~/.cache/backgroundchanged
if [ -f $checkfile ]
then
    conkylauncher=~/.scripts/launchers/conky.sh
    ln -sf ~/.themes/background.png ~/.themes/background
    [ -e $conkylauncher ] && $conkylauncher &
    rm $checkfile
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    killall conky
    touch $checkfile
fi

xfdesktop --reload &
