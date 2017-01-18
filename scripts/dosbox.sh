#!/bin/bash
# Runs DosBox. Prevent DosBox's speed from changing by setting CPU affinity and CPU governor for the specific core.
# If su is required, use tee to echo.
# echo performance | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /dev/null
# echo $oldgov | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /dev/null

oldgov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "CPU0 governor set to performance"
taskset -c 0 /usr/bin/dosbox
echo $oldgov > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "CPU0 governor set to $oldgov"
sleep 2

