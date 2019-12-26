#!/bin/sh
# Sometimes conky just fails to start. Just keep trying.

sleep 2 # When running on startup. Conky might start as part of an old session, but we don't want two instances running.
while [ ! "$(ps -ef | grep "conky -d$")" ]
do
    conky -d
    sleep 3
done
