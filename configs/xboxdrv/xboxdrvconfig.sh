#!/usr/bin/sh
XBOXDRVDIR=/opt/xboxdrv
ln -sf $XBOXDRVDIR/$2.cfg $XBOXDRVDIR/current_$1
echo "Symlink $XBOXDRVDIR/current_$1 now points to $XBOXDRVDIR/$2.cfg."
echo "Connect the $1 controller and press return."
read tmp
