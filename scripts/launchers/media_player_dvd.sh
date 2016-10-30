#!/bin/sh
# Helper script for launching DVDs (DVD image files) in media player.
# Must correspond with media player config.

DEFAULTPROFILE="surroundmovie"
DEFAULTTRACK="1"
EXE="nice -n -1 /usr/bin/mpv --no-osc --cache=no"

if [ "$#" = 0 ]; then
    echo "Usage: media_player_dvd.sh [profile shortcut] [tracknumber] <filename>"
    echo ""
    echo "Valid profile shortcuts:  st   (stereomovie)"
    echo "                          sr   (surroundmovie)"
    echo "                          srbm (surroundmovie balanced matrix)"
    echo "                          h    (hrtfmovie)"
    echo "                          menu (stereomovie) starts from DVD menu"
    echo "                               *do not give tracknumber with this*"
    echo ""
    echo "If profile shortcut is omitted, $DEFAULTPROFILE profile is assumed."
    echo "If tracknumber is omitted, track $DEFAULTTRACK is assumed."
    echo "If tracknumber is given, profile shortcut must be given too."
    exit
fi

# if no optional arguments are given, just play and exit
if [ "$#" = 1 ]; then
    $EXE --profile $DEFAULTPROFILE dvdnav://$DEFAULTTRACK --dvd-device "$1" &
    exit
fi

# set profile
if [ "$1" = "st" ]; then
    profile="stereomovie"
elif [ "$1" = "sr" ]; then
    profile="surroundmovie"
elif [ "$1" = "srbm" ]; then
    profile="surroundmoviebalancedmatrix"
elif [ "$1" = "h" ]; then
    profile="hrtfmovie"
elif [ "$1" = "menu" ]; then
    $EXE --profile stereomovie --input-cursor dvdnav:// --dvd-device "$2" &
    exit
else
    echo "Warning: unknown profile: $1"
    profile="default"
fi 
    
if [ "$#" = 3 ]; then
    track=$2
    filename="$3"
else
    track=$DEFAULTTRACK
    filename="$2"
fi
$EXE --profile $profile dvdnav://$track --dvd-device "$filename" &

