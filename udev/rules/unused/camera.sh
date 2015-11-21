#!/bin/bash
symlink="/dev/camera"
mountpoint="/mnt/camera"
photopath="$mountpoint/DCIM/100PHOTO/"

# Wait for symlink.
iter=0
while [ ! -e $symlink ]
do
	sleep 0.5
	iter=`expr $iter + 1`
	if [ $iter -gt 8 ]
		then exit
	fi
done

sudo mount -o uid=panther,gid=users $symlink $mountpoint

export XAUTHORITY=/home/panther/.Xauthority
export DISPLAY=:0.0

/usr/bin/thunar $photopath &

