#!/bin/sh
# Toggle alternative background.

checkfile="/dev/shm/backgroundchanged"
if [ -f $checkfile ]
then
 ln -sf ~/.themes/crepuscular_rays_crop_browner.png ~/.themes/background
 exec ~/.scripts/launchers/conky.sh &
 rm $checkfile
else
 ln -sf ~/.themes/crepuscular_rays_crop_darker.png ~/.themes/background
 killall conky
 touch $checkfile
fi

xfdesktop --reload &

