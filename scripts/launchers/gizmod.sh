#!/bin/sh
# Gizmo daemon launcher.

[ "$(ps -e | grep gizmod)" ] && killall -9 gizmod

LD_LIBRARY_PATH=/opt/programs/gizmod/lib/ /opt/programs/gizmod/bin/gizmod -A -U -C /opt/programs/gizmod/customgizmo &
