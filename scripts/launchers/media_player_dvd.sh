#!/bin/sh
# Helper script for launching DVDs (DVD image files) in media player.
# Must correspond with media player config.
# Unfortunately most media players do not support DVD menus anymore.

DEFAULTPROFILE="surroundmovie"
track=""
EXE="nice -n -1 /usr/bin/mpv --cache=no"

if [ "$#" = 0 ]; then
    echo "Usage: media_player_dvd.sh [profile shortcut] <filename> [tracknumber]"
    echo ""
    echo "Valid profile shortcuts:  st   (stereomovie)"
    echo "                          sr   (surroundmovie)"
    echo "                          srbm (surroundmovie balanced matrix)"
    echo ""
    echo "If profile shortcut is omitted, $DEFAULTPROFILE profile is assumed."
    exit
fi

# if no optional arguments are given, just play and exit
if [ "$#" = 1 ]; then
    $EXE --profile=$DEFAULTPROFILE dvdread:// --dvd-device="$1" &
    exit
fi

# set profile
if [ "$1" = "st" ]; then
    profile="stereomovie"
elif [ "$1" = "sr" ]; then
    profile="surroundmovie"
elif [ "$1" = "srbm" ]; then
    profile="surroundmoviebalancedmatrix"
elif [ "$1" = "menu" ]; then
    profile="stereomovie --input-cursor"
    track="1"
else
    echo "Warning: unknown profile: $1"
    profile=""
fi 
    
if [ "$#" = 3 ]; then
    track=$3
fi
$EXE ${profile:---profile=$profile} dvdread://$track --dvd-device="$2" &

