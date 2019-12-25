#!/bin/sh
# Display some info about CPU and AMD GPU.

num_cores=$(cat /proc/cpuinfo | grep "cpu cores" | head -n 1 | cut -f 2 -d ':' | tr -d ' ')
echo "CPU core frequencies (showing $num_cores real cores):"
cat /proc/cpuinfo | grep MHz | head -n $num_cores
echo
echo CPU core temperatures:
sensors 2>/dev/null | grep "\(Core [0-9]\)\|\(Tdie\)"
echo
echo Graphics card:
sensors 2>/dev/null | grep -A 6 amdgpu | grep "\(temp\)\|\(edge\)" | cut -f 2 -d ':'
echo
