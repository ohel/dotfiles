#!/bin/sh
# Steam launcher.

cd ~/.steam/root
rm -rf config/htmlcache/*
ps -e | grep pulseaudio || /etc/pulse/alsapipe.pa &
./steam.sh >/tmp/steam.log 2>&1 &
