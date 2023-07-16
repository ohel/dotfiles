#!/bin/bash
# Gather some RSS feeds and create an HTML file from them.

output=~/.local/share/rssfeeds.html
feeds=(
    "http://rss.slashdot.org/Slashdot/slashdotMain"
    "https://www.aljazeera.com/xml/rss/all.xml"
    "https://feeds.yle.fi/uutiset/v1/majorHeadlines/YLE_UUTISET.rss"
)
interval_minutes=30

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
        td:first-child { text-align: right; padding-right: 16px; }
        td { padding: 4px 0; }
    </style>
    </head><body>
    <table><tbody>
EOF

    out_tmp=$(mktemp)
    echo "<hr>" >> $output
    for feed in ${feeds[@]}
    do
        rsstool --sdesc --html -o $out_tmp "$feed"
        sed -i "s/\(^.*\)<a\(.*$\)/<tr><td>\1<\/td><td><a\2<\/td><\/tr>/g" $out_tmp
        sed -i "s/<br>//g" $out_tmp
        tail -n 5 $out_tmp >> $output
        echo "<tr><td colspan=\"2\"><hr></td></tr>" >> $output
    done
    echo "</tbody></table></body></html>" >> $output
    rm $out_tmp

}

while [ 1 ]
do
    get_feeds $output $feeds
    sleep $(expr $interval_minutes \* 60)
done
