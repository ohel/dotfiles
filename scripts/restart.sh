#!/bin/sh
# Safely restart computer.

which zenity 2>/dev/null && ! zenity --question --text="Restart?" && exit

scriptsdir=$(dirname "$(readlink -f "$0")")

# Check if OK to restart.
. $scriptsdir/shutdown_init.sh

sudo shutdown -r now
