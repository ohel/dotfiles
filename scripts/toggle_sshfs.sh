#!/bin/bash
# Given a mountpoint, a remote host and a remote mountpoint, mount or unmount an sshfs.

if [ "$#" -eq 0 ]
then
    echo "Usage: toggle_sshfs.sh <local mountpoint> <remote host> <remote mountpoint>"
    exit
fi

if test "$(mount | grep $1)X" == "X"
then
    echo Mounting $1...
    dir=$(ssh $2 "readlink -f $3")
    sshfs $2:$dir $1
else
    echo Unmounting $1...
    fusermount -u $1
fi
