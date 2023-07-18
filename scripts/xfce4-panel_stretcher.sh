#!/bin/bash
# To prevent OLED burn-in, changes the xfce4-panel length at an interval.

interval=${1:-900}

while [ 1 ]
do
    old_length=$(xfconf-query -c xfce4-panel -p /panels/panel-0/length | cut -f 1 -d '.')
    new_length=$(shuf -i 75-100 -n 1)
    diff=$(expr $new_length - $old_length)

    [ $diff -lt 0 ] && step=-0.25 || step=0.25
    length=$old_length
    rounds=$(expr $diff \* 4)
    [ $rounds -lt 0 ] && rounds=$(expr $rounds \* -1)
    [ $rounds -lt 2 ] && exit 0
    delay=$(echo "scale=3; 1/$rounds" | bc)
    while [ $rounds -gt 0 ]
    do
        rounds=$(expr $rounds - 1)
        length=$(echo "scale=2;  $length + $step" | bc)
        xfconf-query -c xfce4-panel -p /panels/panel-0/length -s $length
        sleep $delay
    done

    sleep $interval
done
