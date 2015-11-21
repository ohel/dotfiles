#!/bin/bash
scanimagebin="/usr/bin/scanimage"
scanner="genesys:libusb:"$(ls -la /dev/canoscan | cut -f 2 -d '>' | cut -f 3-4 -d '/' | sed "s/\//\:/")
mkdir -p /tmp/scans
if [ ! -e scans ]
then
    ln -s /tmp/scans scans
fi
while [ 1 ]
do
    num=$(find ./scans/ -size +0k -iname "scan*.png" | wc -l)
    echo -n "Scanning scan$num.png..."
    errors=1
    while [ $errors -gt 0 ]
    do
        $scanimagebin -d $scanner --mode Color --resolution 300 -p > scans/scan$num.png 2>scanlog.txt
        errors=$(cat scanlog.txt | wc -l)
        if [ $errors -gt 0 ]
        then
            rm scanlog.txt
            echo -n "."
        else
            rm scanlog.txt
            echo
            echo "Press return to scan again, Ctrl-C to quit."
            read
        fi
    done
done

