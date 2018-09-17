#!/bin/sh
# Toggle alternative background using xfdesktop.
# The alternative background kills conky if in use.

if [ "$(basename $(readlink -f ~/.themes/background))" != "background.png" ]
then
    conkylauncher=~/.scripts/launchers/conky.sh
    ln -sf ~/.themes/background.png ~/.themes/background
    [ -e $conkylauncher ] && setsid $conkylauncher
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    killall conky
fi

which xfdesktop 2>/dev/null && setsid xfdesktop --reload
