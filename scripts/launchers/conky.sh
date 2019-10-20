#!/bin/sh
# Sometimes conky just fails to start. Just keep trying.

while [ ! "$(ps -ef | grep "conky -d$")" ]
do
    sleep 2 # When running on startup.
    conky -d
    sleep 3
done
