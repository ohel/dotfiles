#!/bin/sh
# Mount a device using simple-mtpfs.

user=panther

vid=$1 # vendor ID, from udev
mid=$2 # model ID, from udev
options=$3 # -u if unmount, otherwise empty

if [ "$options" = "-u" ]
then
    # Needs array intersection for multiple MTP devices to work nicely.
    mountpoint=$(mount | grep simple-mtpfs | grep -o "/tmp/mtp-mount-..." | head -n 1)
    su $user -c "fusermount -u $mountpoint"
    rmdir $mountpoint
else
    devnum=$(simple-mtpfs -l 2>&1 | tail -n 1 | cut -f 1 -d ':')
    mountpoint=$(mktemp -d /tmp/mtp-mount-XXX)
    chown $user:$user $mountpoint
    chmod 700 $mountpoint
    su $user -c "simple-mtpfs --device $devnum $mountpoint"
fi
