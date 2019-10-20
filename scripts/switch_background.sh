#!/bin/sh
# Toggle alternative background using feh or reloading xfdesktop.
# The alternative background kills conky if in use.

if [ "$(basename $(readlink -f ~/.themes/background))" != "background.png" ]
then
    ln -sf ~/.themes/background.png ~/.themes/background
    conkylauncher=~/.scripts/launchers/conky.sh
    [ -e $conkylauncher ] && setsid $conkylauncher
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    killall conky
fi

which feh 2>/dev/null && feh --no-fehbg --bg-fill ~/.themes/background
which xfdesktop 2>/dev/null && setsid xfdesktop --reload && exit 0
