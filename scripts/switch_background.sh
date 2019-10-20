#!/bin/sh
# Toggle alternative background using feh or reloading xfdesktop.
# The alternative background kills conky if in use.

conkytrigger=~/.cache/switch_bg_conky
if [ "$(basename $(readlink -f ~/.themes/background))" != "background.png" ]
then
    ln -sf ~/.themes/background.png ~/.themes/background
    if [ -e $conkytrigger ]
    then
        rm $conkytrigger
        which conky 2>/dev/null && conky -d
    fi
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    if [ "$(ps -ef | grep "conky -d$")" ]
    then
        killall conky
        touch $conkytrigger
    fi
fi

which feh 2>/dev/null && feh --no-fehbg --bg-fill ~/.themes/background
which xfdesktop 2>/dev/null && setsid xfdesktop --reload && exit 0
