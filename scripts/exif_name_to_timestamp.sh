#!/usr/bin/sh
# Given filenames of form YYYY.mm.dd.HH.MM.SS.* or YYYYmmdd_HHMMSS.* (where . is any character), parse timestamp and write it as UTC AllDates EXIF info.

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
    [ ! "$timestamp" ] && timestamp=$(echo "$inputname" | grep -o "^[0-9]\{8,\}_[0-9]\{6,\}")
    [ ! "$timestamp" ] && echo "Filename is in wrong form." && continue

    if [ $(echo "$timestamp" | grep -o "_") ]
    then
        regex="\(^[0-9]\{4,\}\)\([0-9][0-9]\)\([0-9][0-9]\)_\([0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)"
    else
        regex="\(^[0-9]\{4,\}\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)"
    fi
    year=$(echo "$timestamp"   | sed "s/$regex/\1/")
    month=$(echo "$timestamp"  | sed "s/$regex/\2/")
    day=$(echo "$timestamp"    | sed "s/$regex/\3/")
    hour=$(echo "$timestamp"   | sed "s/$regex/\4/")
    minute=$(echo "$timestamp" | sed "s/$regex/\5/")
    second=$(echo "$timestamp" | sed "s/$regex/\6/")

    exiftool -m -overwrite_original -AllDates="$year-$month-$day $hour:$minute:$second UTC" "$inputname"
    [ "$mode" ] && exiftool -m -overwrite_original -AllDates$mode=$offset:0:0 "$inputname"
done
