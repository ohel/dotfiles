#!/bin/bash
# Power on the default Bluetooth controller and connect to device with MAC $1.
# Assumes the Bluetooth device has been set up beforehand.
# To set up a device, power on a controller using bluetoothctl and pair, trust and connect the device.

BT_DEV_MAC=$1

if ! [ "$BT_DEV_MAC" ]
then
    echo "Give the Bluetooth device MAC as a parameter."
    exit 1
fi

coproc bluetoothctl
echo -e "show\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if [ "$(echo $output | grep 'Powered: no')" ]
then
    echo "Powering on Bluetooth controller..."
    coproc bluetoothctl
    echo -e "power on\nexit" >&${COPROC[1]}
    wait $COPROC_PID
fi

coproc bluetoothctl
echo -e "info $BT_DEV_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if [ "$(echo $output | grep 'Connected: no')" ]
then
    echo "Connecting to device $BT_DEV_MAC..."
    coproc bluetoothctl
    echo -e "connect $BT_DEV_MAC\nexit" >&${COPROC[1]}
    wait $COPROC_PID
else
    echo "Already connected."
    exit 0
fi
