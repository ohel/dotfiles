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

ql=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet.py$")
spotify=$(ps -e | grep " spotify$")

scriptsdir=$(dirname "$(readlink -f "$0")")
spotifydbus="dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player"

if [ "$1" = "play-pause" ]
then
    [ ! "$spotify" ] && "$scriptsdir"/launchers/quodlibet.sh play-pause
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
    # Spotify changes its window title when playing a song, so this only works while paused.
    [ "$spotify" ] && spotifywin=$(wmctrl -l | grep " Spotify$" | cut -f 1 -d ' ')
    [ "$spotifywin" ] && wmctrl -i -R $spotifywin
elif [ "$1" = "random-album" ]
then
    [ "$ql" ] && $ql --random=album
fi
