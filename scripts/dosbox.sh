#!/bin/bash

# To prevent DosBox's speed from changing, set CPU affinity and CPU governor for the specific core.

#echo performance | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /dev/null
oldgov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "CPU0 governor set to performance"
taskset -c 0 /opt/bin/dosbox
#echo conservative | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /dev/null
echo $oldgov > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "CPU0 governor set to $oldgov"
sleep 2

