#!/bin/sh
# A script which checks whether any QEMU-KVM virtual machines are running, or if RAID devices are resyncing.
# Call this script before the actual shutdown (script), this will hold for input if anything needs attention.

if test "X$(ps -ef | grep qemu.* | grep -v grep)" != "X"
then
    echo "A virtual machine is running."
    read tmp
    exit 1
fi

if [ -e /proc/mdstat ]
then
    numraidtotal=$(cat /proc/mdstat | grep "md[0-9]\{1,3\}" | wc -l)
    numraidok=$(cat /proc/mdstat | grep "\([0-9]\)\/\1"| wc -l)
    if ! [ $numraidtotal -eq $numraidok ]
    then
        echo "RAID device note:"
        cat "/proc/mdstat"
        read tmp
        exit 1
    fi

    if test "X$(cat /proc/mdstat | grep resync)" != "X"
    then
        echo "RAID devices resyncing:"
        cat "/proc/mdstat"
        echo
        echo "Press CTRL-C to cancel shutdown, return to continue."
        read tmp
    fi
fi
