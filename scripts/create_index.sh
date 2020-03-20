#!/bin/sh
# Create a simple index.html from directory contents up to one level of sub directories.
# White spaces are not supported in file or directory names.
# A dummy .htaccess file is written also.
# Creates image thumbnail links if they exist (thumb_*.jpg).
# If $3 is given and evaluates to boolean true, images are embedded even without thumbs.

root=${1:-$(basename $(pwd))}
title=${2:-$root}
preview_all=${3:-""}
index="index.html"

echo "Creating index for /$root"

cat > $index << EOF
<html lang="en"><head><meta charset="utf-8">
<style>
    body { background-color: #303030; color:darkgray; padding: 3em; }
    html { font-family: sans-serif; }
    a { color: white; text-decoration: none; }
    img { margin-top: 0.5em; margin-bottom: 2em; }
    li { float: left; margin-right: 3em; margin-bottom: 1em; }
    hr { margin-bottom: 3em; }
    .centered { position: absolute; left: 50%; transform: translateX(-50%); }
    ol.centered li { float: none; }
</style>
</head><body>
<script>
    function toggleSingleColumn() {
      const list = document.getElementById("mainlist");
      list.classList.toggle("centered");
    }
</script>
<h1>$title</h1>
<input type="checkbox" onclick="toggleSingleColumn()" id="toggle">
<label for="toggle">Single column</label>
<hr>
<ol id="mainlist">
EOF

# Files in base directory, with thumbnails.
for filename in $(find ./ -maxdepth 1 -type f | sort)
do
    item=$(basename "$filename")
    size=$(du -h "$filename" | xargs echo | cut -f 1 -d ' ')
    if [ "$item" != "index.html" ] &&
        [ "$item" != ".htaccess" ] &&
        [ ! "$(echo $item | grep "thumb_.*\.\(\(jpg\)\|\(png\)\)")" ]
    then
        echo "<li><a href=\"/$root/$item\">$item</a> ($size)" >> $index
        [ "${item##*.}" = "mp4" ] && echo " [VIDEO]" >> $index
        if [ -e thumb_${item%.*}.jpg ] || [ -e thumb_${item%.*}.png ]
        then
            ext=jpg
            [ -e thumb_${item%.*}.png ] && ext=png
            echo "<a href=\"/$root/$item\"></br><img src=\"thumb_${item%.*}.$ext\" alt=\"img\"></a>" >> $index
        elif [ "$preview_all" ] && $([ "${item##*.}" = "jpg" ] || [ "${item##*.}" = "png" ])
        then
            echo "<a href=\"/$root/$item\"></br><img src=\"$item\" alt=\"img\"></a>" >> $index
        fi
        echo "</li>" >> $index
    fi
done
echo "</ol><ul>" >> $index

# Subdirectories.
for filepath in $(find ./ -maxdepth 1 -mindepth 1 -type d | sort)
do
    path=$(basename "$filepath")
    echo "<li><a href=\"/$root/$path\">$path</a>" >> $index

    # Files in a subdirectory.
    echo "<ol>" >> $index
    for i in $(find "$filepath" -maxdepth 1 -mindepth 1 -type f | sort)
    do
        file=$(basename "$i")
        echo "<li><a href=\"/$root/$path/$file\">$file</a></li>" >> $index
    done
    echo "</ol></li>" >> $index
done
echo "</ul></body></html>" >> $index

cat > .htaccess << EOF
RewriteCond %{HTTP:X-Forwarded-Proto} !https
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
DirectoryIndex $index
EOF
chmod a+r .htaccess $index

echo "Created $index and .htaccess files."
echo "Remember to chmod -R a+r the linked files and directories."
