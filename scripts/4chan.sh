#!/bin/bash
# Download images from a 4chan thread.
wget -O - $1 |
grep -Eo 'i.4cdn.org/[^"]+' |
uniq |
xargs wget
