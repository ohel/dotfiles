#!/usr/bin/sh
# CompizConfig Settings Manager launcher.
# Compiz 0.9 series with prefix /opt/programs/compiz.

pv=$(python -V | grep -o "3\.[0-9]\{1,\}")
env LD_LIBRARY_PATH=/opt/programs/compiz/lib64 \
PYTHONPATH=/opt/programs/compiz/lib/python$pv/site-packages:/opt/programs/compiz/lib64/python$pv/site-packages \
/opt/programs/compiz/bin/ccsm &
