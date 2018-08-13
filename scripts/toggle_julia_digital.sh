#!/bin/bash
# Toggles ESI Juli@ digital out playback source (with monitor, if monitor parameter given). May be used with analog out because of the monitor.
# For best results, run with:
# /usr/bin/terminal --hide-borders --geometry 50x10 -x toggle_digital_source.sh autoclose [monitor]

autoclose=0
monitor=0
if [ "$1" = "autoclose" ] || [ "$2" = "autoclose" ]; then
    autoclose=1
fi
if [ "$1" = "monitor" ] || [ "$2" = "monitor" ]; then
    monitor=1
fi

if amixer -cJuli get 'IEC958',0 | grep ".* Item0: 'PCM Out'" > /dev/null
then
    echo "Redirecting digital in (L, R) to digital out."
    amixer -cJuli set 'IEC958',0 'IEC958 In L' > /dev/null
    amixer -cJuli set 'IEC958',1 'IEC958 In R' > /dev/null
    if [ $monitor -gt 0 ]; then
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
    if [ $monitor -gt 0 ]; then
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

if [ $autoclose -gt 0 ]; then
    sleep 0.5
    exit
fi
