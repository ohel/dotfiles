#!/usr/bin/bash
# If using multiple Bluetooth audio devices with BlueALSA,
# select one by creating a proper ALSA configuration file
# based on bluetoothctl device listing and user selection.
# Only the Bluetooth device section is written to the config.

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

# Have to call version or some other dummy command for the devices listing to
# be complete here. No idea why it is so, but at least this works.
coproc bluetoothctl
echo -e "devices\nversion\nexit" >&${COPROC[1]}
output=$(cat <&${COPROC[0]})

echo "Select device [1-9] for .asoundrc:"
echo ""

index=0
while read -r device
do
    devices[$index]=$device
    index=$(expr $index + 1)
    echo $device
done <<< $(echo $output | sed "s/Device /\n /g" | grep ..: | sed "s/\[bluetooth\].*//" | grep -n .)

read -s -N 1 index
selected=${devices[$(expr $index - 1)]}
device_mac=$(echo $selected | cut -f 2 -d ' ')
device_name=$(echo $selected | cut -f 3- -d ' ')
tput init
echo ""

if [ -e ~/.asoundrc ] && [ "$1" != "nobak" ]
then
    echo "Found ~/.asoundrc, moving it to ~/.asoundrc.bak."
    mv ~/.asoundrc ~/.asoundrc.bak
fi

cat > ~/.asoundrc << EOF
pcm.bluetooth {
    type plug
    slave.pcm {
        type bluealsa
        device { @func concat
            strings [ "$device_mac" ]
        }
        profile "a2dp"
    }
}
EOF

echo "Created ~/.asoundrc with pcm.bluetooth pointing to $device_name."
