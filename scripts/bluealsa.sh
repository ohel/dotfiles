#!/bin/bash
# Connect to device with MAC address ALSA_BLUETOOTH_MAC as set in the environment.
# Uses a helper script to connect.
# Assumes bluealsa is running.

if test "X$ALSA_BLUETOOTH_MAC" == "X"
then
    echo "Define the environment variable ALSA_BLUETOOTH_MAC first."
    exit 1
fi

if test "X$(ps -e | grep bluealsa | grep -v `basename "$0"`)" == "X"
then
    echo "Bluealsa is not running."
    exit 1
fi

scriptsdir=$(dirname "$(readlink -f "$0")")
$scriptsdir/bt_dev_connect.sh $ALSA_BLUETOOTH_MAC
sleep 2

echo "Checking Bluetooth device."
coproc bluetoothctl
echo -e "info $BT_DEV_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Connected: yes')" == "X"
then
    echo "Connection did not succeed yet."
    exit 1
fi
