#!/bin/bash
# Backup or restore Chromium default profile bookmarks, preferences and extensions.
# This is to avoid using Google accounts.

zipname=${1:-config_chromium_default.zip}
profiledir=${2:-~/.config/chromium/Default}
cwd=$(pwd)

if ! [ -e $profiledir ];
then
    echo "Error: directory $profiledir does not exist."
    exit
fi

if [ "$#" == 0 ]
then
    cd $profiledir
    echo "Zipping Chromium default profile bookmarks, preferences and extensions..."
    zip -q -r $cwd/$zipname Bookmarks Preferences Extensions
    cd $cwd
    echo "Created zip $zipname."
    exit
fi

echo "Restoring Chromium default profile bookmarks, preferences and extensions from zip..."
unzip -q "$zipname" -d $profiledir
echo "Extracted zip $zipname."
