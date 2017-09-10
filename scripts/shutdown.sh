#!/bin/bash
# A two-phase shutdown script I use.
# First check if it is OK to shut down.
# Then backup stuff if necessary and shut down.
# Also enable Wake-On-LAN in case it is disabled somehow.

scriptsdir=$(dirname "$(readlink -f "$0")")

source $scriptsdir/shutdown_init.sh

if test "X$(which ethtool 2>/dev/null)" != "X"
then
    for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
    do
        ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
        if test "X$ip" != "X"
        then
            ethtool -s $physical_device wol g
            break
        fi
    done
fi

source $scriptsdir/shutdown_backup.sh
