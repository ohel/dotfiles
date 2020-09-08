#!/bin/sh
# A script which checks whether any QEMU-KVM virtual machines are running, or if RAID devices are resyncing.
# Call this script before the actual shutdown (script), this will hold for input if anything needs attention.

if [ "$(ps -ef | grep qemu.* | grep -v grep)" ]
then
    echo "A virtual machine is running."
    read tmp
    exit 1
fi

if [ -e /proc/mdstat ]
then
    numraidtotal=$(cat /proc/mdstat | grep "active raid1" | wc -l)
    numraidok=$(cat /proc/mdstat | grep "\[\([0-9]\)\/\1\]"| wc -l)
    if ! [ $numraidtotal -eq $numraidok ]
    then
        echo "RAID device note:"
        cat "/proc/mdstat"
        read tmp
        exit 1
    fi

    if [ "$(cat /proc/mdstat | grep resync)" ]
    then
        echo "RAID devices resyncing:"
        cat "/proc/mdstat"
        echo
        echo "Press Ctrl-C to cancel shutdown, return to continue."
        read tmp
    fi
fi
