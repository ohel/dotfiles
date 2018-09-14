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

checkconnection() {
    coproc bluetoothctl
    echo -e "info $1\nexit" >&${COPROC[1]}
    output=$(cat <&${COPROC[0]})
    return $(test "X$(echo $output | grep 'Connected: yes')" == "X")
}

scriptsdir=$(dirname "$(readlink -f "$0")")
if $scriptsdir/bt_dev_connect.sh $ALSA_BLUETOOTH_MAC;
then
    echo "Waiting for connection."
    seconds=20
    while [ $seconds -gt 0 ]
    do
        seconds=$(expr $seconds - 1)
        if checkconnection $ALSA_BLUETOOTH_MAC
        then
            sleep 1
        else
            exit 0
        fi
    done
    echo "Connection did not succeed yet."
    exit 1
fi
