#!/usr/bin/sh
# Create a simple index.html from directory contents up to one level of sub directories.
# White spaces are not supported in file or directory names.
# A dummy .htaccess file is written also.
# Creates image thumbnail links if they exist (thumb_*.jpg).
# If RAW images exist for corresponding jpgs, skip thumbs for them.
#
# Parameters:
# $1: name of the root directory (for hyperlinks); defaults to current directory basename
# $2: title for the index page; defaults to $1
# $3: if given and evaluates to boolean true, images are embedded even without thumbs.
#
# If there's a file named update.sh, it is omitted from the index.
# For an image gallery, the update.sh contents could be something like this:
    # #!/usr/bin/sh
    # create_thumbs.sh 600 *.jpg *.png
    # create_index.sh root Root
    # chmod o+r *
    # chmod o+x .
    # rsync -ah --progress --delete ./ server:~/public_html/root

root=${1:-$(basename $(pwd))}
title=${2:-$root}
preview_all=${3:-""}
index="index.html"
# Raw image file extensions separated by spaces. Case is ignored.
raw_exts_space_separated=" rw2 raw "
# Video file extensions separated by spaces. Case is ignored.
video_exts_space_separated=" mp4 mov "

echo "Creating index for /$root"

cat > $index << EOF
<html lang="en"><head><meta charset="utf-8">
<style>
    body { background-color: #303030; color:darkgray; padding: 3em; }
    html { font-family: sans-serif; }
    a { color: white; text-decoration: none; }
    a.hash { color: #80d0ff; }
    img { margin-top: 0.5em; margin-bottom: 2em; }
    li { float: left; margin-right: 3em; margin-bottom: 1em; }
    hr { margin-bottom: 3em; }
    .centered { position: absolute; left: 50%; transform: translateX(-50%); }
    ol.centered li { float: none; }
</style>
</head><body>
<script>
    function toggleMultiColumn() {
        const list = document.getElementById("mainlist");
        list.classList.toggle("centered");
        if (list.classList.contains("centered")) {
            localStorage.removeItem("columnMode");
        } else {
            localStorage.setItem("columnMode", "multi");
        }
    }
</script>
<h1>$title</h1>
<input type="checkbox" onclick="toggleMultiColumn()" id="toggle">
<label for="toggle">View in multiple columns</label>
<hr>
<ol id="mainlist" class="centered">
EOF

li=1

# Files in base directory, with thumbnails. This basically creates an image gallery.
for filename in $(find ./ -maxdepth 1 -type f | sort)
do
    item=$(basename "$filename")
    size=$(du -h "$filename" | xargs echo | cut -f 1 -d ' ')
    if [ "$item" != "index.html" ] &&
        [ "$item" != ".htaccess" ] &&
        [ "$item" != "update.sh" ] &&
        [ ! "$(echo $item | grep "thumb_.*\.\(\(jpg\)\|\(png\)\)")" ]
    then
        echo "<li id=li$li><a href=\"/$root/$item\">$item</a> <a href=\"#li$li\" class=\"hash\">⚓</a> ($size)" >> $index

        # Videos.
        [ "$(echo "$video_exts_space_separated" | grep -i "${item##*.}")" ] && echo " [VIDEO]" >> $index

        # Raw images.
        handle_raw=0
        [ "$(echo "$raw_exts_space_separated" | grep -i "${item##*.}")" ] && handle_raw=1
        [ $handle_raw -eq 1 ] && echo " [RAW]" >> $index

        if [ -e thumb_${item%.*}.jpg ] || [ -e thumb_${item%.*}.png ]
        then
            ext=jpg
            [ -e thumb_${item%.*}.png ] && ext=png

            # Skip raw image if jpg exists.
            [ ! -e "${item%.*}.jpg" ] && [ ! -e "${item%.*}.JPG" ] && handle_raw=0
            [ $handle_raw -eq 0 ] && echo "<a href=\"/$root/$item\"></br><img src=\"thumb_${item%.*}.$ext\" alt=\"img\"></a>" >> $index
        elif [ "$preview_all" ] && $([ "${item##*.}" = "jpg" ] || [ "${item##*.}" = "png" ])
        then
            echo "<a href=\"/$root/$item\"></br><img src=\"$item\" alt=\"img\"></a>" >> $index
        fi
        echo "</li>" >> $index
        li=$(expr $li + 1)
    fi
done
echo "</ol><ul>" >> $index

# Subdirectory listing.
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

# Store the column mode selection to local storage to ease browsing.
cat >> $index << EOF
</ul>
<script>
    const columnMode = localStorage.getItem("columnMode");
    if (columnMode === "multi") {
        const toggle = document.getElementById("toggle");
        toggle.checked = true;
        const list = document.getElementById("mainlist");
        list.classList.remove("centered");
    }
</script>
</body></html>
EOF

cat > .htaccess << EOF
RewriteCond %{HTTP:X-Forwarded-Proto} !https
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
DirectoryIndex $index
EOF
chmod a+r .htaccess $index

echo "Created $index and .htaccess files."
echo "Remember to chmod -R a+r the linked files and directories, e.g. in root:"
echo "chmod -R a+r * .htaccess && chmod a+x ."
