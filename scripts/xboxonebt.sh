#!/bin/bash
# Power on the default bluetooth controller and connect to device: XBOX_BLUETOOTH_MAC.
# Assumes the bluetooth device has been paired beforehand and xpadneo is installed.
# To pair a device, power on a controller using bluetoothctl and pair, trust, and connect the device.
# xpadneo: https://github.com/atar-axis/xpadneo

if test "X$XBOX_BLUETOOTH_MAC" == "X"
then
    echo "Define the environment variable XBOX_BLUETOOTH_MAC first."
    exit
fi
BT_DEV_MAC=$XBOX_BLUETOOTH_MAC

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
echo -e "info $BT_DEV_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Connected: yes')" == "X"
then
    echo "Connecting to device $BT_DEV_MAC."
    coproc bluetoothctl
    echo -e "connect $BT_DEV_MAC\nexit" >&${COPROC[1]}
    wait $COPROC_PID
else
    echo "Already connected."
fi
