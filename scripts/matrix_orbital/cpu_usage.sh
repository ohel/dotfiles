#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

while true
do
    column=2
    for idletimes in $(mpstat -P ALL 1 1 | tr -s [' '] | grep "Average: \w " | cut -f 11 -d ' ')
    do
        usage=$(awk -v idle="$idletimes" 'BEGIN { printf "%.0f", (100.0 - idle)/6.25 }')
        if [ $usage -eq 16 ]
        then
            usagestring="20"
        elif [ $usage -gt 7 ]
        then
            usagestring="1"$(expr $usage - 8)
        else
            usagestring="0"$usage
        fi
        printf "\xFE\x3D\002%s\00%s" "$column" "$usagestring" > $dev
        sleep 0.01
        column=$(expr $column + 1)
    done
done
