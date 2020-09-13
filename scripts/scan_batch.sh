#!/bin/bash
# Batch scanning script for a scanner. The scanner or the driver causes the
# scanning operation to fail sometimes. This script takes care of that.
# With Canon LiDE 200, there might also be a bug which causes the scans
# to be weirdly deformed unless color mode and high enough resolution is used.
# Scanner ID (for grepping) may be given as $1.
# If $2 includes "hi", higher resolution/quality is used.

scanner_id=${1:-"lide 200"}
scanimagebin="/usr/bin/scanimage"
scanner=$(scanimage -L | grep -i "$scanner_id" | cut -f 2 -d '`' | cut -f 1 -d "'")
scandir=/tmp/scans
log=scanlog.txt

mkdir -p $scandir
setsid -f thunar $scandir >/dev/null 2>&1

bits=8
res=300
[ "$(echo "lo$2" | grep hi)" ] && bits=16 && res=600
echo "Using scanner $scanner, resolution $res, $bits bits"

while [ 1 ]
do
    num=$(find $scandir/ -size +0k -iname "scan*.png" | wc -l)
    fnum=$num
    [ $num -lt 10 ] && fnum="0$fnum"
    echo -n "Scanning scan$fnum.png..."
    errors=1
    while [ $errors -gt 0 ]
    do
        $scanimagebin -d $scanner --format=png --mode Color --depth $bits --resolution $res -p > $scandir/scan$fnum.png 2>$scandir/$log
        sed -i "s/Progress:[^\r]*%\r//g" $scandir/$log
        errors=$(cat $scandir/$log | wc -l)
        if [ $errors -gt 0 ]
        then
            rm $scandir/$log
            echo -n "."
        else
            rm $scandir/$log
            echo
            echo "Press return to scan again, Ctrl-C to quit."
            read
        fi
    done
done
