#!/bin/sh
# Steam launcher.

cd /opt/programs/steam/
rm config/htmlcache/*
env SDL_AUDIODRIVER=alsa ./steam.sh &
