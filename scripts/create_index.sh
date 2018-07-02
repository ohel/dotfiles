#!/bin/bash
# Create a simple index.html from directory contents up to one level of sub directories.
# White spaces are not supported in file or directory names.
# A dummy .htaccess file is written also.
# Creates image thumbnail links if they exist (thumb_*.jpg).

root=${1:-$(basename $(pwd))}
index="index.html"

echo "Creating index for /$root"

echo "<html lang=\"en\"><head><meta charset=\"utf-8\">" > $index
echo "<style> a { text-decoration: none; } </style>" >> $index
echo "</head><body><ol>" >> $index
for filename in `find ./ -maxdepth 1 -type f | sort`; do
    item=`basename "$filename"`
    if test "$item" != "index.html" &&
       test "$item" != ".htaccess" &&
       test "X$(echo $item | grep thumb_.*\.jpg)" = "X"
    then
       echo "<li><a href=\"/$root/$item\">$item" >> $index
       if test "X$(ls thumb_${item%.*}.jpg 2>/dev/null)" != "X"
       then
           echo "</br><img src=\"thumb_${item%.*}.jpg\" alt=\"img\">" >> $index
       fi
       echo "</a></li>" >> $index
    fi
done
echo "</ol><ul>" >> $index
for filepath in `find ./ -maxdepth 1 -mindepth 1 -type d | sort`
do
    path=`basename "$filepath"`
    echo "<li>$path" >> $index
    echo "<ol>" >> $index
    for i in `find "$filepath" -maxdepth 1 -mindepth 1 -type f | sort`
    do
        file=`basename "$i"`
        echo "<li><a href=\"/$root/$path/$file\">$file</a></li>" >> $index
    done
    echo "</ol></li>" >> $index
done
echo "</ul></body></html>" >> $index

echo "RewriteEngine off" > .htaccess
echo "DirectoryIndex $index" >> .htaccess

chmod a+r .htaccess $index

echo "Created index.html and .htaccess."
echo "Remember to chmod -R a+r the files and directories."
