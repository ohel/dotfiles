#!/bin/sh
# Sometimes conky just fails to start. Just keep trying.

while [ ! "$(ps -e | grep conky | grep -v conky.sh)" ]
do
    sleep 2
    conky -d
    sleep 3
done
