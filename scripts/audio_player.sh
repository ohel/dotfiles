#!/bin/sh
# If an audio player is running, send command given in $1.
# Audio players:
#    * Quod Libet
#    * Spotify
# Commands:
#    * play-pause
#    * previous
#    * next
#    * toggle-window
#    * random-album

ql=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet\(.py\)\?$")
spotify=$(ps -e | grep " spotify$")

scriptsdir=$(dirname "$(readlink -f "$0")")
spotifydbus="dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player"

if [ "$1" = "play-pause" ]
then
    [ "$spotify" ] || "$scriptsdir"/launchers/quodlibet.sh play-pause
    [ "$spotify" ] && $spotifydbus.PlayPause
elif [ "$1" = "previous" ]
then
    [ "$ql" ] && $ql --seek=0:0
    [ "$ql" ] && $ql --previous
    [ "$spotify" ] && $spotifydbus.Previous
elif [ "$1" = "next" ]
then
    [ "$ql" ] && $ql --next
    [ "$spotify" ] && $spotifydbus.Next
elif [ "$1" = "toggle-window" ]
then
    [ "$ql" ] && $ql --toggle-window
    [ "$spotify" ] && spotifywin=$(wmctrl -lx | grep -i "spotify.spotify" | cut -f 1 -d ' ')
    if [ "$spotifywin" ]
    then
        if [ "$(xwininfo -id $spotifywin | grep IsUnMapped)" ]
        then
            xdotool windowmap $spotifywin
        else
            xdotool windowminimize $spotifywin
        fi
    fi
elif [ "$1" = "random-album" ]
then
    [ "$ql" ] && $ql --random=album
fi
