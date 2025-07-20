#!/usr/bin/sh
# CompizConfig Settings Manager launcher.
# Compiz 0.9 series installed with custom prefix.

prefix=/opt/programs/compiz

pv=$(python -V | grep -o "3\.[0-9]\{1,\}")
shebangv=$(head -n 1 $prefix/bin/ccsm | grep -o "3\.[0-9]\{1,\}")
[ "$pv" != "$shebangv" ] && echo "Wrong shebang Python version for ccsm binary!" && exit 1
[ ! -e $prefix/lib/python$pv ] && echo "Wrong Python version for site-packages!" && exit 1

env LD_LIBRARY_PATH=$prefix/lib64 \
PYTHONPATH=$prefix/lib/python$pv/site-packages \
$prefix/bin/ccsm &
