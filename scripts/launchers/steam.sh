#!/bin/sh
# Steam launcher.

cd ~/.steam/root
rm config/htmlcache/*
env SDL_AUDIODRIVER=alsa ./steam.sh &
