#!/bin/sh
# Display some info about CPU and GPU (AMD).

echo
echo CPU core frequencies:
cat /proc/cpuinfo | grep MHz
echo
echo CPU core temperatures:
sensors | grep -A 4 Physical
if test "$(uname -r | grep rt)" != "$(uname -r)"
then
	echo
	echo Graphics card:
	amdconfig --odgc | grep -B 1 Current
	amdconfig --odgc | grep load
	amdconfig --odgt | grep Sensor
fi

