#!/usr/bin/sh
# Steam launcher.

ps -e | grep pulseaudio || /etc/pulse/alsapipe.pa &

if [ -e ~/.steam ]
then
    cd ~/.steam/root
    rm -rf config/htmlcache/*
    ./steam.sh "$@" >/tmp/steam.log 2>&1 &
else
    # Steam can't handle symlinks in media directories but fails immediately.
    for link in $(find ~/.var/app/com.valvesoftware.Steam/media/ -type l)
    do
        rm $link
    done

    /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam --file-forwarding com.valvesoftware.Steam "$@" >/tmp/steam.log 2>&1 &

    # Steam tries creating the symlinks again and again until it fails, so check and remove if they are being created. Wait 30 seconds for Steam to start.
    counter=0
    while [ $counter -lt 30 ]
    do
        for link in $(find ~/.var/app/com.valvesoftware.Steam/media/ -type l)
        do
            rm $link
        done
        sleep 1
        counter=$(expr $counter + 1)
    done
fi
