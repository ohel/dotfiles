#!/usr/bin/sh
# Zero empty space on a file system. Use another smaller file so that filling out the space doesn't result in hiccups.

dd if=/dev/zero of=zero.small.file bs=1024 count=102400
cat /dev/zero > zero.file
sync
rm zero.small.file
rm zero.file
