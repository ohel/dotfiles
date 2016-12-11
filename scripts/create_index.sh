#!/bin/bash
# Create a simple index.html from directory contents up to one level of sub directories.
# White spaces are not supported in file or directory names.
# A dummy .htaccess file is written also.

root=${1:-"."}
index="index.html" 

echo "<html lang=\"en\"><head><meta charset=\"utf-8\"></head><body>" > $index
echo "<ul>" > $index
for filename in `find ./ -maxdepth 1 -type f | sort`; do
    item=`basename "$filename"`
    if test "$item" != "index.html"; then
        echo "  <li><a href=\"/$root/$item\">$item</a></li>" >> $index
    fi
done
echo "</ul><ul>" >> $index
for filepath in `find ./ -maxdepth 1 -mindepth 1 -type d | sort`; do
  path=`basename "$filepath"`
  echo "  <li>$path</li>" >> $index
  echo "  <ul>" >> $index
  for i in `find "$filepath" -maxdepth 1 -mindepth 1 -type f | sort`; do
    file=`basename "$i"`
    echo "    <li><a href=\"/$root/$path/$file\">$file</a></li>" >> $index
  done
  echo "  </ul>" >> $index
done
echo "</ul>" >> $index
echo "</body></html>" >> $index

echo "RewriteEngine off" > .htaccess
echo "DirectoryIndex $index" >> .htaccess

chmod a+r .htaccess $index

echo "Created index.html and .htaccess."
echo "Remember to chmod -R a+r the files and directories."
