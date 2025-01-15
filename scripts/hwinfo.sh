#!/usr/bin/sh
# Display some info about CPU and AMD GPU.

num_cores=$(grep "cpu cores" /proc/cpuinfo | head -n 1 | cut -f 2 -d ':' | tr -d ' ')
echo "CPU core frequencies (showing $num_cores real cores):"
grep MHz /proc/cpuinfo | head -n $num_cores
echo
echo "CPU temperature (core / Core Complex Die / T Control):"
sensors 2>/dev/null | grep "\(Core [0-9]\)\|\(Tdie\)\|\(Tccd\)\|\(Tctl\)"
echo
echo Graphics card:
sensors 2>/dev/null | grep -A 6 amdgpu | grep "\(temp\)\|\(edge\)" | cut -f 2 -d ':'
echo
