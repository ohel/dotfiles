#!/bin/sh
# Steam launcher.

cd /opt/programs/steam/
rm config/htmlcache/*
SDL_AUDIODRIVER=alsa ./steam.sh &
