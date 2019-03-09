#!/bin/sh
# Change screen color temperature using the redshift tool.

tempfile=~/.cache/redshift_temp
default=6000
max=6500
min=3500
if [ ! -e $tempfile ]
then
    echo $default > $tempfile
fi
current=$(cat $tempfile);

if [ "$#" -gt 0 ]
then
    new=$(echo $current + $1 | bc)
    if [ $new -gt $max ]
    then
        new=$max
    elif [ $new -lt $min ]
    then
        new=$min
    fi
    echo $new > $tempfile
    current=$new
fi

# The -P reset parameter was introduced in redshift 1.12.
version=$(redshift -V | cut -f 2 -d ' ' | tr -d '.')
[ $version -gt 111 ] && resetparam="-P"

redshift $resetparam -O $current
