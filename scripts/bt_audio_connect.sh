#!/bin/bash
# Connect to device with MAC address ALSA_BLUETOOTH_MAC (environment variable).
# Prefer pcm.bluetooth device MAC if defined in ~/.asoundrc or /etc/asound.conf.
# Override MAC may be given as $1.
# Uses a helper script to connect.

mac=$(grep -A 20 "pcm\.bluetooth" .asoundrc 2>/dev/null | grep -o "\(..:\)\{5\}.." | grep -v "[0:]\{17\}")
[ $mac ] || mac=$(grep -A 20 "pcm\.bluetooth" /etc/asound.conf 2>/dev/null | grep -o "\(..:\)\{5\}.." | grep -v "[0:]\{17\}")
[ $mac ] || mac=$ALSA_BLUETOOTH_MAC
[ $1 ] && mac=$1

if [ ! "$mac" ]
then
    echo "Define the environment variable ALSA_BLUETOOTH_MAC first."
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

# Despite waiting infinitely, with certain audio devices
# the connection doesn't always succeed on first try.
# In that case simply trying again almost always works.
retries=3
while [ $retries -gt 0 ]
do
    if $scriptsdir/bt_dev_connect.sh $mac
    then
        seconds=10
        while [ $seconds -gt 0 ]
        do
            ! checkconnection $mac && echo "Connected to $mac " && exit 0
            sleep 1
            seconds=$(expr $seconds - 1)
        done
    fi
    retries=$(expr $retries - 1)
    echo "Retrying connection..."
done

echo "Connection did not succeed yet."
exit 1
