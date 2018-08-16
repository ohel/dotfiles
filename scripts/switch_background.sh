#!/bin/bash
# Toggle alternative background when using xfdesktop.
# The alternative background kills conky if in use.

if test "X$(basename $(readlink -f ~/.themes/background))" != "Xbackground.png"
then
    conkylauncher=~/.scripts/launchers/conky.sh
    ln -sf ~/.themes/background.png ~/.themes/background
    [ -e $conkylauncher ] && $conkylauncher &
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    killall conky
fi

xfdesktop --reload &
