#!/bin/bash
echo "                    " > /dev/ttyUSB0
sleep 0.01
echo "                    " > /dev/ttyUSB0
sleep 0.01
while true
do

echo "      $(date +%T)      " > /dev/ttyUSB0
sleep 0.01
echo "" > /dev/ttyUSB0
sleep 1
echo "      $(date +%T)      " > /dev/ttyUSB0
sleep 0.01
echo "" > /dev/ttyUSB0
sleep 1
echo "      $(date +%T)      " > /dev/ttyUSB0
sleep 0.01
echo "" > /dev/ttyUSB0
sleep 1
echo "      $(date +%T)      " > /dev/ttyUSB0
sleep 0.01
echo "" > /dev/ttyUSB0
sleep 1
echo "      $(date +%T)      " > /dev/ttyUSB0
cputemp="$(sensors | grep -A 2 k10temp | grep temp1 | tr -s ' ' | cut -f 2 -d ' ' | cut -c 2- | tr -d '°C')"
gputemp="$(aticonfig --odgt | grep Sensor | tr -s [' '] | cut -f 6 -d ' ' | cut -c -4)"
echo "CPU $cputemp    GPU $gputemp" > /dev/ttyUSB0
sleep 1

done
