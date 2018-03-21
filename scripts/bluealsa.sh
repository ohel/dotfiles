#!/bin/bash
# Power on the default bluetooth controller and connect to device: ALSA_BLUETOOTH_MAC.
# Assumes the bluetooth device has been paired beforehand and bluealsa is running.
# To pair a device, power on a controller using bluetoothctl and trust, pair and connect the device.

if test "X$ALSA_BLUETOOTH_MAC" == "X"
then
    echo "Define the environment variable ALSA_BLUETOOTH_MAC first."
    exit
fi

if test "X$(ps -e | grep bluealsa | grep -v `basename "$0"`)" == "X"
then
    echo "Bluealsa is not running."
    exit
fi

echo "Checking bluetooth controller."
coproc bluetoothctl
echo -e "show\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Powered: yes')" == "X"
then
    echo "Powering on bluetooth controller."
    coproc bluetoothctl
    echo -e "power on\nexit" >&${COPROC[1]}
    wait $COPROC_PID
fi

echo "Checking bluetooth device."
coproc bluetoothctl
echo -e "info $ALSA_BLUETOOTH_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Connected: yes')" == "X"
then
    echo "Connecting to device $ALSA_BLUETOOTH_MAC."
    coproc bluetoothctl
    echo -e "connect $ALSA_BLUETOOTH_MAC\nexit" >&${COPROC[1]}
    wait $COPROC_PID
else
    echo "Already connected."
fi
