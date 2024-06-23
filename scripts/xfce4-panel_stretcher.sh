#!/usr/bin/sh
# To prevent OLED burn-in, changes the xfce4-panel length at an interval.

scriptname=$(basename $0)
existing_scripts=$(ps -ef | grep "/usr/bin/sh .*$scriptname$" | grep -v grep | wc -l)
[ $existing_scripts -gt 2 ] && echo "Panel stretcher already running." && exit 1

interval=${1:-900}

easeInOutExp200Steps() {
    if [ $1 -eq 0 ]
    then
        factor=0
    elif [ $1 -eq 200 ]
    then
        factor=1
    elif [ $1 -lt 100 ]
    then
        factor="e(($1/10 - 10) * l(2)) / 2"
    else
        factor="(2 - e((-$1/10 + 10) * l(2))) / 2"
    fi

    echo "$2 + $3 * $factor" | bc -l
}

while [ 1 ]
do
    old_length=$(xfconf-query -c xfce4-panel -p /panels/panel-0/length | cut -f 1 -d '.')
    new_length=$(shuf -i 75-100 -n 1)
    diff=$(expr $new_length - $old_length)

    step=1
    while [ $step -lt 201 ]
    do
        length=$(easeInOutExp200Steps $step $old_length $diff)
        xfconf-query -c xfce4-panel -p /panels/panel-0/length -s $length
        sleep 0.0075
        step=$(expr $step + 1)
    done

    sleep $interval
done
