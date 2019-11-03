#!/bin/sh
# CompizConfig Settings Manager launcher.
# Compiz 0.9 series with prefix /opt/programs/compiz.

env LD_LIBRARY_PATH=/opt/programs/compiz/lib64 \
PYTHONPATH=/opt/programs/compiz/lib/python2.7/site-packages:/opt/programs/compiz/lib64/python2.7/site-packages \
/opt/programs/compiz/bin/ccsm &
