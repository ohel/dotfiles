#!/bin/bash

# ready vertical bars and empty the screen
echo -e "\0376\0166\0376X" > /dev/ttyUSB0
sleep 0.5

interval=0
while true
do

if [ $interval -eq 0 ]
then
	cputemp="$(sensors | grep temp2 | tr -s ' ' | cut -f 2 -d ' ' | cut -c 2- | tr -d '°C')"
	echo -e "\0376\0107\0006\0002$cputemp\0376\0107\0006\0001$(date +"%a  %H:%M")" > /dev/ttyUSB0
fi

usagecolumn=1
for idletimes in $(mpstat -P ALL 1 1 | tr -s [' '] | grep "Average: \w " | cut -f 11 -d ' ')
do
	usage=$(echo "(100.0-$idletimes)/6.25" | bc)
	if [ $usage -eq 16 ]
		then usagestring="20"
	else
		if [ $usage -gt 7 ]
			then usagestring="1"`expr $usage - 8`
		else usagestring="0"$usage
		fi
	fi
	echo -e "\0376\0075\000$usagecolumn\00$usagestring" > /dev/ttyUSB0
	sleep 0.1
	usagecolumn=`expr $usagecolumn + 1`
done

interval=`expr $interval + 1`
if [ $interval -gt 3 ]
	then interval=0
fi

done

