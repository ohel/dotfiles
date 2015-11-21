#!/bin/sh
echo "                    " > /dev/ttyUSB0
sleep 0.01
echo "                    " > /dev/ttyUSB0
sleep 0.01
while true
do
cputemp="$(sensors | grep -A 2 k10temp | grep temp1 | tr -s ' ' | cut -f 2 -d ' ' | cut -c 2- | tr -d '°C') C"
gputemp="$(aticonfig --odgt | grep Sensor | tr -s [' '] | cut -f 6 -d ' ' | cut -c -4) C"
echo "     CPU $cputemp" > /dev/ttyUSB0
sleep 0.01
echo "     GPU $gputemp" > /dev/ttyUSB0
sleep 5
done
