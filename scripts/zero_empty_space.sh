#!/usr/bin/sh
# Zero empty space on a file system. Use another smaller file so that filling out the space doesn't result in hiccups.
# By default synchronized IO is used unless $1 = async. A big blocksize is used to take advantage of write buffers, but using fully async IO might result in the final sync practically hanging up a device.

echo Writing small zero file...
dd if=/dev/zero of=zero.small.tmp bs=100M count=1 conv=fsync
oflag="oflag=dsync"
[ "$1" = "async" ] && oflag=""
echo Writing zero file until space runs out...
if command -v pv >/dev/null
then
    pv -f -pterab /dev/zero | dd of=zero.tmp bs=128M conv=fsync $oflag
else
    dd if=/dev/zero of=zero.tmp bs=128M conv=fsync status=progress $oflag
fi
rm zero.small.tmp
rm zero.tmp
sync
echo All done.
