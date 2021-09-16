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
        which conky >/dev/null 2>&1 && conky -d
    fi
else
    ln -sf ~/.themes/background_alt.png ~/.themes/background
    if [ "$(ps -ef | grep "conky -d$")" ]
    then
        killall conky
        touch $conkytrigger
    fi
fi

which feh >/dev/null 2>&1 && feh --no-fehbg --bg-fill ~/.themes/background
which xfdesktop >/dev/null 2>&1 && setsid xfdesktop --reload && exit 0
