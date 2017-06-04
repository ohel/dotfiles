#/bin/sh
cd /opt/programs/steam/
rm config/htmlcache/*
SDL_AUDIODRIVER=alsa LD_PRELOAD='/usr/lib/gcc/x86_64-pc-linux-gnu/5.4.0/32/libstdc++.so.6' ./steam.sh &
