#!/usr/bin/sh
# Given filenames of form YYYY.mm.dd.HH.MM.SS.* (where . is any character), parse timestamp and write it as UTC AllDates EXIF info.

[ ! "$1" ] && echo "Missing arguments." && exit 1

if [ "$(which zenity 2>/dev/null)" ]
then
    offset=$(zenity --title="Timezone compensation" --text="Enter X for UTC+X hours (prefix with - for negative):" --entry)
    if [ "$offset" ]
    then
        mode="-"
        [ "$(echo $offset | grep -o "^-")" ] && mode="+"
    fi
fi

for inputname in "$@"
do
    timestamp=$(echo "$inputname" | grep -o "^[0-9]\{4,\}.[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9]")
    [ ! "$timestamp" ] && echo "Filename is in wrong form." && continue

    year=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\1/")
    month=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\2/")
    day=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\3/")
    hour=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\4/")
    minute=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\5/")
    second=$(echo "$timestamp" | sed "s/\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)/\6/")

    exiftool -m -overwrite_original -AllDates="$year-$month-$day $hour:$minute:$second UTC" "$inputname"
    [ "$mode" ] && exiftool -m -overwrite_original -AllDates$mode=$offset:0:0 "$inputname"
done
