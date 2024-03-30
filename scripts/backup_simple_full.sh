#!/usr/bin/sh
# Simple full system backup into a mountpoint $1 using rsync.
# Optionally backup is done using prefix $2 (useful for offline system backup).

backupmount=${1:-"/mnt/usb-backup"}
prefix="$2"

[ ! "$(mount | grep $backupmount)" ] && echo "$backupmount not mounted" && exit 1
[ "$(whoami)" != "root" ] && echo "$(whoami) != root" && exit 1

rsync -avu --delete \
  --exclude $prefix/dev/shm/\* \
  --exclude $prefix/media/\* \
  --exclude $prefix/mnt/\* \
  --exclude $prefix/proc/\* \
  --exclude $prefix/run/\* \
  --exclude $prefix/sys/\* \
  --exclude $prefix/tmp/\* \
  --exclude node_modules \
  $prefix/ $backupmount/
