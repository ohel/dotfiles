#!/bin/sh
# Display some info about CPU and AMD GPU.

echo CPU core frequencies:
cat /proc/cpuinfo | grep MHz
echo
echo CPU core temperatures:
sensors 2>/dev/null | grep "Core [0-9]"
echo
echo Graphics card:
sensors 2>/dev/null | grep -A 6 amdgpu | grep "\(temp\)\|\(edge\)" | cut -f 2 -d ':'
echo
