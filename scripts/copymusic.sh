#!/bin/bash

mountpoint="/mnt/phone"
destination="/mnt/phone/Music"

list=""
album=""
while [ 1 ]
do
	echo "Drag flac, ogg or mp3 files to the terminal window to start copying:"
	read list

	if test "empty$list" == "empty"
    	then
        echo "Unmounting $mountpoint..."
        sudo umount $mountpoint
        echo "Done."
        sleep 2
        exit
	fi

    echo "Type in an album name or leave empty to read from tags:"
    read album
    echo "COPYING AND ENCODING:"
    echo -n "| 0% "
    spacecount=$(expr $(expr $(echo $list | wc -w) \* 3) - 11)
    while [ $spacecount -gt 0 ]
    do
        spacecount=$(expr $spacecount - 1)
        echo -n " "
    done
    echo "100% |"
    album=$(echo "$album" | sed s/" "/_/)
    echo $list | tr " " "\000" | xargs --null -I {} -n 1 -P 3 ~/.scripts/copymusic_encode.sh "$destination" "{}" "$album"
    echo ""
	echo "All done."
	echo ""
done

