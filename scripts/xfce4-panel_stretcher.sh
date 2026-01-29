#!/usr/bin/sh
# To prevent OLED burn-in, changes the xfce4-panel length at an interval.

scriptname=$(basename $0)
existing_scripts=$(ps -ef | grep "/usr/bin/sh .*$scriptname$" | grep -v grep | wc -l)
[ $existing_scripts -gt 2 ] && echo "Panel stretcher already running." && exit 1

interval=${1:-900}

easeInOutExp200Steps() {
    awk -v old=$1 -v diff=$2 '
    function pow2(x) { return exp(x * log(2)) }

    BEGIN {
        for (step = 1; step <= 200; step++) {
            if (step < 100) {
                f = pow2(step/10 - 10) / 2
            } else {
                f = (2 - pow2(-step/10 + 10)) / 2
            }
            printf "%.10f\n", old + diff * f
        }
    }'
}

while [ 1 ]
do
    old_length=$(xfconf-query -c xfce4-panel -p /panels/panel-0/length | cut -f 1 -d '.')
    new_length=$(shuf -i 75-100 -n 1)
    diff=$(expr $new_length - $old_length)

    easeInOutExp200Steps $old_length $diff | while read length; do
        xfconf-query -c xfce4-panel -p /panels/panel-0/length -s $length
        sleep 0.0075
    done

    sleep $interval
done
