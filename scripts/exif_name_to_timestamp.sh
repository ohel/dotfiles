#!/usr/bin/sh
# From a filename $1 of form YYYY.mm.dd.HH.MM.SS.* (where . is any character), parse timestamp and write it as UTC AllDates EXIF info.

timestamp=$(echo "$1" | grep -o "^[0-9]\{4,\}.[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9]")
[ ! "$timestamp" ] && echo "Filename is in wrong form." && exit 1

year=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\1/")
month=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\2/")
day=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\3/")
hour=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\4/")
minute=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\5/")
second=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\6/")


exiftool -m -overwrite_original -AllDates="$year-$month-$day $hour:$minute:$second UTC" "$1"
