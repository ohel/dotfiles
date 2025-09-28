#!/usr/bin/bash
# Every 30 minutes, parse some RSS feeds from URLs read from ~/.config/rss_feeds and create an HTML file ~/.local/share/rss_feeds.html from them.
# Uses the Python script rss_parser.py to output table rows. That script should exist in the same directory as this file.

input=~/.config/rss_feeds
output=~/.local/share/rss_feeds.html
interval_minutes=30

scriptdir=$(dirname "$(readlink -f "$0")")
scriptname=$(basename $0)
existing_scripts=$(ps -ef | grep "/usr/bin/bash .*$scriptname$" | grep -v grep | wc -l)
[ $existing_scripts -gt 2 ] && echo "RSS feeds script already running." && exit 1

get_feeds() {

    output=$1
    feeds=$2

    cat > $output << EOF
<html lang="en"><head>
<title>RSS Feeds</title>
<meta charset="utf-8">
<style>
    body { background-color: #303030; color:darkgray; padding: 3em; }
    html { font-family: sans-serif; }
    a { color: white; text-decoration: none; }
    a.hash { color: #80d0ff; }
    table { margin-left: auto; margin-right: auto; }
    td:first-child { text-align: right; padding-right: 16px; }
    td:last-child { text-align: left; padding-right: 0; }
    td { padding: 4px 0; }
</style>
</head><body>
<table><tbody>
<tr><td colspan="2"><hr></td></tr>
EOF

    out_tmp=$(mktemp)
    for feed in ${feeds[@]}
    do
        $scriptdir/rss_parser.py "$feed" >> $output
        echo '<tr><td colspan="2"><hr></td></tr>' >> $output
    done
    echo "</tbody></table></body></html>" >> $output
    rm $out_tmp

}

while [ 1 ]
do
    readarray feeds < $input
    get_feeds $output $feeds
    sleep $(expr $interval_minutes \* 60)
done
