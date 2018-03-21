#!/bin/bash
# A common shutdown script I use.

scriptsdir=$(dirname "$(readlink -f "$0")")

# Check if OK to shut down.
source $scriptsdir/shutdown_init.sh

# Enable Wake-On-Lan.
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

# Do backups if necessary.
source $scriptsdir/backup_interval.sh

echo "Shutting down..."
sudo shutdown -hP now
