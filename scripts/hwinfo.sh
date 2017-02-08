#!/bin/sh
# Display some info about CPU and GPU (AMD).

echo CPU core frequencies:
cat /proc/cpuinfo | grep MHz
echo
echo CPU core temperatures:
sensors | grep -A 4 Physical
echo
echo Graphics card:
if test "X$(which amdconfig 2>/dev/null)" != "X"
then
	amdconfig --odgc | grep -B 1 Current
	amdconfig --odgc | grep load
	amdconfig --odgt | grep Sensor
else
    sensors | grep -A 2 radeon | tail -n 1 | cut -f 2 -d '+' | cut -f 1 -d ' '
fi
echo
