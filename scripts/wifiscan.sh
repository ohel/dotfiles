#!/bin/sh
sudo iwlist wlp1s0 scan | grep ESSID | cut -f 2 -d ":" | sed 's/^"\(.*\)"$/\1/'
