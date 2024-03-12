#!/bin/sh
# Steam launcher.

ps -e | grep pulseaudio || /etc/pulse/alsapipe.pa &

if [ -e ~/.steam ]
then
    cd ~/.steam/root
    rm -rf config/htmlcache/*
    ./steam.sh >/tmp/steam.log 2>&1 &
else
    /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam --file-forwarding com.valvesoftware.Steam >/tmp/steam.log 2>&1 &
fi
