#!/usr/bin/sh
# If an audio player is running, send command given in $1.
# Audio players:
#    * Quod Libet
#    * Spotify
# Commands:
#    * play-pause
#    * previous
#    * next
#    * toggle-window
#    * random

ql=$(ps -ef | grep -o "\([^ ]\{1,\}quodlibet\(.py\)\?$\)\|\(\/usr\/bin\/quodlibet\)")
qlcontrol="$HOME/.quodlibet/control"
spotify=$(ps -e | grep " spotify$")

scriptsdir=$(dirname "$(readlink -f "$0")")
spotifydbus="dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2"

if [ "$1" = "play-pause" ]
then
    [ "$spotify" ] || "$scriptsdir"/launchers/quodlibet.sh play-pause
    [ "$spotify" ] && $spotifydbus org.mpris.MediaPlayer2.Player.PlayPause
elif [ "$1" = "previous" ]
then
    [ "$ql" ] && echo "seek 0:0" > $qlcontrol
    [ "$ql" ] && echo previous > $qlcontrol
    [ "$spotify" ] && $spotifydbus org.mpris.MediaPlayer2.Player.Previous
elif [ "$1" = "next" ]
then
    [ "$ql" ] && echo next > $qlcontrol
    [ "$spotify" ] && $spotifydbus org.mpris.MediaPlayer2.Player.Next
elif [ "$1" = "toggle-window" ]
then
    [ "$ql" ] && echo toggle-window > $qlcontrol
    [ "$spotify" ] && spotifywin=$(wmctrl -lx | grep -i "spotify.spotify" | cut -f 1 -d ' ')
    if [ "$spotifywin" ]
    then
        [ "$(xwininfo -id $spotifywin | grep IsUnMapped)" ] && wincmd=windowmap || wincmd=windowminimize
        xdotool $wincmd $spotifywin
    fi
elif [ "$1" = "random" ]
then
    if [ "$ql" ]
    then
        echo "random album" > $qlcontrol
        sleep 0.25
        echo next > $qlcontrol
    elif [ "$spotify" ]
    then
        shuffle=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Shuffle | grep -o true)
        [ ! "$shuffle" ] && $spotifydbus org.freedesktop.DBus.Properties.Set string:org.mpris.MediaPlayer2.Player string:Shuffle variant:boolean:true
        $spotifydbus org.mpris.MediaPlayer2.Player.Next
        [ ! "$shuffle" ] && $spotifydbus org.freedesktop.DBus.Properties.Set string:org.mpris.MediaPlayer2.Player string:Shuffle variant:boolean:false
    fi
fi
