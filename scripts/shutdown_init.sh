#/bin/bash
if test "X$(ps -ef | grep qemu.* | grep -v grep)" != "X"
then
    echo "A virtual machine is running."
    read
    exit
fi

numraidtotal=$(cat /proc/mdstat | grep "md[0-9]\{1,3\}" | wc -l)
numraidok=$(cat /proc/mdstat | grep "\([0-9]\)\/\1"| wc -l)
if ! [ $numraidtotal -eq $numraidok ]
then
    echo "RAID device note:"
    cat "/proc/mdstat"
    read
    exit
fi

if test "X$(cat /proc/mdstat | grep resync)" != "X"
then
    echo "RAID devices resyncing:"
    cat "/proc/mdstat"
    echo
    echo "CTRL-C to cancel shutdown."
    read
fi
