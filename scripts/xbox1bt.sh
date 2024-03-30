#!/usr/bin/sh
# Connect to device with MAC address XBOX1_BLUETOOTH_MAC as set in the environment.
# Uses a helper script to connect.
# Assumes xpadneo is installed: https://github.com/atar-axis/xpadneo
# The Enhanced Re-Transmission Mode for BT no longer needs to be disabled starting with kernel 5.12.
# To check ERTM: /sys/module/bluetooth/parameters/disable_ertm

if [ ! "$XBOX1_BLUETOOTH_MAC" ]
then
    echo "Define the environment variable XBOX1_BLUETOOTH_MAC first."
    exit 1
fi

scriptsdir=$(dirname "$(readlink -f "$0")")
$scriptsdir/bt_dev_connect.sh $XBOX1_BLUETOOTH_MAC
