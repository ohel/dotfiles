#!/bin/sh
# Safely restart computer.

which zenity 2>/dev/null && ! zenity --question --text="Restart?" && exit

. /home/panther/.scripts/shutdown_init.sh
sudo shutdown -r now
