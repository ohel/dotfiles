#!/usr/bin/sh
# Safely restart computer.

if [ "$(which zenity 2>/dev/null)" ] && [ "$DISPLAY" ]
then
    ! zenity --question --text="Restart?" && exit
else
    echo Restart?
    echo Press return to continue, Ctrl-C to abort.
    read tmp
fi

scriptsdir=$(dirname "$(readlink -f "$0")")

# Check if OK to restart.
. $scriptsdir/shutdown_init.sh

sudo shutdown -r now
