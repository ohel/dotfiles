#!/bin/sh
# Open a LUKS device (or file vault), activate an LVM volume group if there is one, and mount a partition.
# If partition is already mounted, unmount, deactivate and close the device.
# Partition is assumed to be in /etc/fstab and mount point in /mnt/name.

name="$1" # Name of mountpoint and LUKS mapping.
dev_uuid="$2" # UUID of the block device (e.g. /dev/sda or /dev/md1), or filename if a file vault.
vg_name="$3" # Optional name of LVM volume group.
keyfile="${4:-/mnt/$1_key}" # Optional LUKS key location.

if [ "$(mount | grep "$name ")" ] || [ "$(dmsetup ls | grep "$name ")" ]
then
    mountpoint=$(mount | grep "$name " | cut -f 3 -d ' ')
    [ "$mountpoint" ] && umount $mountpoint 2>/dev/null || echo Nothing to unmount.
    [ ! "$vg_name" ] || vgchange -an $vg_name 2>/dev/null || echo Volume group $vg_name not found, nothing to deactivate.
    cryptsetup close $name && echo Removed LUKS mapping $name.
    exit
fi

# Search for file vaults.
[ -e $dev_uuid ] && dev=$dev_uuid
# Search MD devices.
[ ! "$dev" ] && dev=$(blkid /dev/md/* | grep $dev_uuid | cut -f 1 -d ':')
# Search NVMe devices.
[ ! "$dev" ] && dev=$(blkid /dev/nvme* | grep $dev_uuid | cut -f 1 -d ':')
# Search SCSI devices.
[ ! "$dev" ] && dev=$(blkid /dev/sd* | grep $dev_uuid | cut -f 1 -d ':')

[ ! "$dev" ] && echo "Device not found." && exit 1

keyopts=""
[ -e $keyfile ] && keyopts="--key-file $keyfile"
cryptsetup open --type luks $dev $name $keyopts && echo Created LUKS mapping $name.
[ "$vg_name" ] && pvscan --cache --activate ay $(realpath /dev/mapper/$name) && echo Activated volume group $vg_name.
[ -e /mnt/$name ] && mount /mnt/$name && mounted=1
[ "$mounted" != 1 ] && [ -e $name ] && mount /dev/mapper/$name $name
[ "$(mount | grep $name)" ] && echo Mounted $name. || echo Failed to mount $name.
