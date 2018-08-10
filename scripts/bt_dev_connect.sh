#!/bin/bash
# Power on the default Bluetooth controller and connect to device with MAC $1.
# Assumes the Bluetooth device has been set up beforehand.
# To set up a device, power on a controller using bluetoothctl and pair, trust and connect the device.

BT_DEV_MAC=$1

if test "X$BT_DEV_MAC" == "X"
then
    echo "Give the Bluetooth device MAC as a parameter."
    exit
fi

echo "Checking Bluetooth controller."
coproc bluetoothctl
echo -e "show\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Powered: yes')" == "X"
then
    echo "Powering on Bluetooth controller."
    coproc bluetoothctl
    echo -e "power on\nexit" >&${COPROC[1]}
    wait $COPROC_PID
fi

echo "Checking Bluetooth device."
coproc bluetoothctl
echo -e "info $BT_DEV_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Connected: yes')" == "X"
then
    echo "Connecting to device: $BT_DEV_MAC"
    coproc bluetoothctl
    echo -e "connect $BT_DEV_MAC\nexit" >&${COPROC[1]}
    wait $COPROC_PID
else
    echo "Already connected."
fi
