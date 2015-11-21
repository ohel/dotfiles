#!/bin/sh
checkfile=~/ramdisk/backlightoff
if [ -f $checkfile ]
then
	echo -e "\xFE\x42\x00" > /dev/ttyUSB0
	rm $checkfile
else
	echo -e "\xFE\x46" > /dev/ttyUSB0
	touch $checkfile
fi

