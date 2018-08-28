#!/bin/bash
# Connect to device with MAC address ALSA_BLUETOOTH_MAC as set in the environment.
# Uses a helper script to connect.
# Assumes BlueALSA is running.

if test "X$ALSA_BLUETOOTH_MAC" == "X"
then
    echo "Define the environment variable ALSA_BLUETOOTH_MAC first."
    sleep 1
    exit 1
fi

if test "X$(ps -e | grep bluealsa | grep -v `basename "$0"`)" == "X"
then
    echo "BlueALSA is not running."
    sleep 1
    exit 1
fi

scriptsdir=$(dirname "$(readlink -f "$0")")
if $scriptsdir/bt_dev_connect.sh $ALSA_BLUETOOTH_MAC;
then
    echo "Waiting for connection."
    sleep 10
fi

echo "Checking Bluetooth device."
coproc bluetoothctl
echo -e "info $BT_DEV_MAC\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})
if test "X$(echo $output | grep 'Connected: yes')" == "X"
then
    echo "Connection did not succeed yet."
    sleep 1
    exit 1
fi
