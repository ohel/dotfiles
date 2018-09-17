#!/bin/sh
# Connect to device with MAC address XBOX_BLUETOOTH_MAC as set in the environment.
# Uses a helper script to connect.
# Assumes xpadneo is installed: https://github.com/atar-axis/xpadneo

if [ ! "$XBOX_BLUETOOTH_MAC" ]
then
    echo "Define the environment variable XBOX_BLUETOOTH_MAC first."
    exit 1
fi

scriptsdir=$(dirname "$(readlink -f "$0")")
$scriptsdir/bt_dev_connect.sh $XBOX_BLUETOOTH_MAC
