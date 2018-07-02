#!/bin/bash
# Create a simple index.html from directory contents up to one level of sub directories.
# White spaces are not supported in file or directory names.
# A dummy .htaccess file is written also.
# Creates image thumbnail links if they exist (thumb_*.jpg).

root=${1:-$(basename $(pwd))}
index="index.html"

echo "Creating index for /$root"

cat > $index << EOF
<html lang="en"><head><meta charset="utf-8">
<style>
    body { padding-left: 3em; }
    html { font-family: sans-serif; }
    a { text-decoration: none; }
    img { margin-top: 0.5em; }
    hr { border-style: outset; border-width: 2px; }
</style>
</head><body><ol>
EOF

# Files in base directory, with thumbnails.
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
        echo "</a></li><hr>" >> $index
    fi
done
echo "</ol><ul>" >> $index

# Subdirectories.
for filepath in `find ./ -maxdepth 1 -mindepth 1 -type d | sort`
do
    path=`basename "$filepath"`
    echo "<li><a href=\"/$root/$path\">$path</a>" >> $index

    # Files in a subdirectory.
    echo "<ol>" >> $index
    for i in `find "$filepath" -maxdepth 1 -mindepth 1 -type f | sort`
    do
        file=`basename "$i"`
        echo "<li><a href=\"/$root/$path/$file\">$file</a></li>" >> $index
    done
    echo "</ol></li>" >> $index
done
echo "</ul></body></html>" >> $index

cat > .htaccess << EOF
RewriteEngine off
DirectoryIndex $index
EOF
chmod a+r .htaccess $index

echo "Created $index and .htaccess files."
echo "Remember to chmod -R a+r the linked files and directories."
