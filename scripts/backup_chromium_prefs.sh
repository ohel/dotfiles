#!/usr/bin/sh
# Backup or restore Chromium default profile bookmarks, preferences and extensions.
# This is to avoid using Google accounts.
# $1: name of the backup file (optional)
# $2: location of the default profile directory (optional)
# $3: if equals to "backup", create a backup, otherwise restore from given zip
# If no parameters given, create backup. If $1 or $2 given, restore backup.

zipname=${1:-config_chromium_default.zip}
profiledir=$2
cwd=$(pwd)

if [ ! "$profiledir" ]
then
    [ -e ~/.config/chromium/Default ] && profiledir=~/.config/chromium/Default
    [ -e ~/.var/app/org.chromium.Chromium/config/chromium/Default ] && profiledir=~/.var/app/org.chromium.Chromium/config/chromium/Default
elif ! [ -e $profiledir ]
then
    echo "Error: directory $profiledir does not exist."
    echo "Create it? (Input y to create, any other string to exit.)"
    read create
    echo
    [ "$create" != "y" ] && exit 1
    mkdir $profiledir
    ! [ -e $profiledir ] && echo "Unable to create $profiledir." && exit 1
fi

if [ "$#" = 0 ] || [ "$3" = "backup" ]
then
    cd $profiledir
    echo Zipping Chromium default profile data in:
    echo "$profiledir"
    echo
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

echo Restoring Chromium default profile data to:
echo "$profiledir"
echo
unzip -q "$zipname" -d $profiledir
echo "Extracted zip $zipname."
