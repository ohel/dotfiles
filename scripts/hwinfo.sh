#!/bin/sh
# Display some info about CPU and AMD GPU.

echo CPU core frequencies:
cat /proc/cpuinfo | grep MHz
echo
echo CPU core temperatures:
sensors 2>/dev/null | grep "Core [0-9]"
echo
echo -n Graphics card:
if test "X$(which amdconfig 2>/dev/null)" != "X"
then
	amdconfig --odgc | grep -B 1 Current
	amdconfig --odgc | grep load
	amdconfig --odgt | grep Sensor
else
    sensors 2>/dev/null | grep -A 6 amdgpu | grep temp | cut -f 2 -d ':'
fi
echo
