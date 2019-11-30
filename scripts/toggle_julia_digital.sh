#!/bin/sh
# Toggles ESI Juli@ digital out playback source (with monitor, if monitor parameter given). May be used with analog out because of the monitor.
# For best results, run with:
# /usr/bin/terminal --hide-borders --geometry 50x10 -x toggle_digital_source.sh autoclose [monitor]
# Put in ~/.scripts_extra/toggle_audio.sh for xbindkeys_mmkeys compatibility.

autoclose=0 # If run in a terminal, will close it.
monitor=0
([ "$1" = "autoclose" ] || [ "$2" = "autoclose" ]) && autoclose=1
([ "$1" = "monitor" ] || [ "$2" = "monitor" ]) && monitor=1

if amixer -cJuli get 'IEC958',0 | grep ".* Item0: 'PCM Out'" > /dev/null
then
    echo "Redirecting digital in (L, R) to digital out."
    amixer -cJuli set 'IEC958',0 'IEC958 In L' > /dev/null
    amixer -cJuli set 'IEC958',1 'IEC958 In R' > /dev/null
    if [ $monitor -gt 0 ]
    then
        echo "Enabling monitor digital in."
        amixer -cJuli set 'Monitor Digital In',0 unmute > /dev/null
    fi
    echo "Juli@ is now playing audio from:"
    echo
    echo "   ####  #  ###  # #####  ###  #        # #   #"
    echo "   #   # # #     #   #   #   # #        # ##  #"
    echo "   #   # # # ### #   #   ##### #        # # # #"
    echo "   #   # # #   # #   #   #   # #        # #  ##"
    echo "   ####  #  ###  #   #   #   # #####    # #   #"
else
    echo "Setting digital out to 'PCM Out'."
    amixer -cJuli set 'IEC958',0 'PCM Out' > /dev/null
    amixer -cJuli set 'IEC958',1 'PCM Out' > /dev/null
    if [ $monitor -gt 0 ]
    then
        echo "Disabling monitor digital in."
        amixer -cJuli set 'Monitor Digital In',0 mute > /dev/null
    fi
    echo "Juli@ is now playing audio from:"
    echo
    echo "                 ###   ### #   #"
    echo "                 #  # #    ## ##"
    echo "                 ###  #    # # #"
    echo "                 #    #    #   #"
    echo "                 #     ### #   #"
fi

if [ $autoclose -gt 0 ]
then
    sleep 0.5 || sleep 1
    exit
fi
