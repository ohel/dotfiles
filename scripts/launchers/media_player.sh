#!/bin/sh
# Helper script for launching video files in media player.
# Must correspond with media player config.

DEFAULTPROFILE="hda"
EXE="nice -n -1 /usr/bin/mpv --no-osc"

if [ "$#" = 0 ]; then
    echo "Usage: media_player.sh [profile shortcut] <filename>"
    echo ""
    echo "Valid profile shortcuts:  hda  (hda)"
    echo "                          j    (julia)"
    echo "                          st   (stereomovie)"
    echo "                          sr   (surroundmovie)"
    echo "                          srbm (surroundmovie balanced matrix)"
    echo "                          h    (hrtfmovie)"
    echo ""
    echo "If profile shortcut is omitted, $DEFAULTPROFILE profile is assumed."
    exit
fi

# if no optional arguments are given, just play and exit
if [ "$#" = 1 ]; then
    $EXE --profile $DEFAULTPROFILE "$1" &
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
elif [ "$1" = "j" ]; then
    profile="julia"
elif [ "$1" = "hda" ]; then
    profile="hda"
else
    echo "Warning: unknown profile: $1"
    profile=$DEFAULTPROFILE
fi 
    
$EXE --profile $profile "$2" &

