#!/bin/sh
if [ $(sudo rfkill list bluetooth | grep yes | wc -l) -gt 0 ]
then
    sudo rfkill unblock bluetooth
else
    sudo rfkill block bluetooth
fi
