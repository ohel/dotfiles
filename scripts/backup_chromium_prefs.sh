#!/bin/bash
# Backup or restore Chromium default profile bookmarks, preferences and extensions.
# This is to avoid using Google accounts.

zipname=${1:-config_chromium_default.zip}
profiledir=${2:-~/.config/chromium/Default}
cwd=$(pwd)

if ! [ -e $profiledir ]
then
    echo "Error: directory $profiledir does not exist."
    echo "Create it? (Press y to create, any other key to exit.)"
        read -n1 create
        echo
        if test "X$create" = "Xy"
        then
            mkdir $profiledir
        else
            exit 1
        fi
    if ! [ -e $profiledir ]
    then
        echo "Unable to create $profiledir."
        exit 1
    fi
fi

if [ "$#" == 0 ]
then
    cd $profiledir
    echo "Zipping Chromium default profile data."
    zip -q -r $cwd/$zipname \
        Extensions \
        Extension\ State \
        Extension\ Cookies \
        Extension\ Rules \
        Local\ Extension\ Settings \
        Managed\ Extension\ Settings \
        Sync\ Extension\ Settings \
        Local\ Storage\chrome-extension* \
        databases/chrome-extension* \
        IndexedDB/chrome-extension* \
        Login\ Data \
        Web\ Data \
        Cookies \
        Preferences \
        Bookmarks
    cd $cwd
    echo "Created zip $zipname."
    exit
fi

echo "Restoring Chromium default profile data."
unzip -q "$zipname" -d $profiledir
echo "Extracted zip $zipname."
