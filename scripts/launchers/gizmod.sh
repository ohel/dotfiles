#!/bin/sh
# Gizmo daemon launcher.

if test "$(ps -e | grep gizmod)"
    then killall -9 gizmod
fi
LD_LIBRARY_PATH=/opt/programs/gizmod/lib/ /opt/programs/gizmod/bin/gizmod -A -U -C /opt/programs/gizmod/customgizmo &
