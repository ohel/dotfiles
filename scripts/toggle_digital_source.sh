#!/bin/bash
# Toggles ESI Juli@ digital out playback source (with monitor). May be used with analog out because of the monitor.
# For best results, run with:
# /usr/bin/terminal --hide-borders --geometry 50x10 -x toggle_digital_source.sh autoclose

if amixer -cJuli get 'IEC958',0 | grep ".* Item0: 'PCM Out'" > /dev/null
 then
  echo "Digital out (left) was set to 'PCM Out'."
  echo "Redirecting digital in to digital out."
  echo "Enabling monitor digital in."
  amixer -cJuli set 'IEC958',0 'IEC958 In L' > /dev/null
  amixer -cJuli set 'IEC958',1 'IEC958 In R' > /dev/null
  amixer -cJuli set 'Monitor Digital In',0 unmute > /dev/null
  echo "Juli@ is now playing audio from:"
  echo
  echo "   ####  #  ###  # #####  ###  #        # #   #"
  echo "   #   # # #     #   #   #   # #        # ##  #"
  echo "   #   # # # ### #   #   ##### #        # # # #"
  echo "   #   # # #   # #   #   #   # #        # #  ##"
  echo "   ####  #  ###  #   #   #   # #####    # #   #"

else
 if amixer -cJuli get 'IEC958',0 | grep ".* Item0: 'IEC958 In L'" > /dev/null
  then
   echo "Digital out (left) was set to 'IEC958 In L'."
   echo "Resetting digital out to default value 'PCM Out'."
   echo "Disabling monitor digital in."
   amixer -cJuli set 'IEC958',0 'PCM Out' > /dev/null
   amixer -cJuli set 'IEC958',1 'PCM Out' > /dev/null
   amixer -cJuli set 'Monitor Digital In',0 mute > /dev/null
   echo "Juli@ is now playing audio from:"
   echo
   echo "                 ###   ### #   #"
   echo "                 #  # #    ## ##"
   echo "                 ###  #    # # #"
   echo "                 #    #    #   #"
   echo "                 #     ### #   #"
 fi
fi

if [ "$1" = "autoclose" ]
 then sleep 0.4
fi

