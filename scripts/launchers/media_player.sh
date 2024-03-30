#!/usr/bin/bash
# Helper script for launching video files in media player.
# Must correspond with media player config.

DEFAULTPROFILE="general"
EXE="nice -n -1 /usr/bin/mpv "

if [ "$#" = 0 ]
then
    echo "Usage: media_player.sh [profile shortcut] <filename>"
    echo ""
    echo "Valid profile shortcuts:"
    echo "                          general (general)"
    echo "                          st      (stereomovie)"
    echo "                          sr      (surroundmovie)"
    echo "                          srbm    (surroundmoviebalancedmatrix)"
    echo "                          openal  (openalmovie)"
    echo ""
    echo "If profile is omitted or none of the above, the default is: $DEFAULTPROFILE"
    exit
fi

if [ "$#" = 1 ]
then
    $EXE --profile=$DEFAULTPROFILE "$1" &
    exit
fi

if [ "$1" = "st" ]
then
    profile="stereomovie"
elif [ "$1" = "sr" ]
then
    profile="surroundmovie"
elif [ "$1" = "srbm" ]
then
    profile="surroundmoviebalancedmatrix"
elif [ "$1" = "openal" ]
then
    profile="openalmovie"
else
    echo "Using $DEFAULTPROFILE"
    profile=$DEFAULTPROFILE
fi

# This enables passing other parameters instead of just a filename.
$EXE --profile=$profile "${@:2}" &
