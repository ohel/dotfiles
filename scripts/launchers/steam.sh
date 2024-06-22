#!/usr/bin/sh
# Steam launcher.

ps -e | grep pulseaudio || /etc/pulse/alsapipe.pa &

if [ -e ~/.steam ]
then
    cd ~/.steam/root
    rm -rf config/htmlcache/*
    ./steam.sh "$@" >/tmp/steam.log 2>&1 &
else
    # If your XDG directory (defined in ~/.config/user-dirs.dirs) is a symbolic link,
    # Flatpak creates a copy of the symlink to Steam's media directory.
    # Steam can't handle symlinks but fails immediately.
    # Removing the symlinks doesn't seem to work anymore, either.
    if [ $(find ~/.var/app/com.valvesoftware.Steam/media/ -type l | wc -l) -gt 0 ]
    then
        msg="Found symbolic link in Steam's media directory."
        echo $msg
        [ "$(which zenity 2>/dev/null)" ] && zenity --title="Steam error" --text="$msg" --error
        exit 1
    fi

    /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam --file-forwarding com.valvesoftware.Steam "$@" >/tmp/steam.log 2>&1 &
fi
