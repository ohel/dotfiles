#!/bin/bash
# Update a kernel by compiling a new kernel if it exists, using old config file as base.
# Copies the necessary files to the boot partition and updates grub.conf.
# If $1 == rt, realtime kernel is updated instead.

prefix="linux"

cwd="$(pwd)"

if test "$(echo $HOME)" != "/root"
then
    echo "You must be root to update kernel."
    exit
fi

if [ ! -e /usr/src/linux ]
then
    echo "The symbolic link /usr/src/linux does not exist, aborting."
    exit
fi

cd /usr/src
if test "X$1" != "Xrt"
then
    old_version=$(readlink linux | cut -f 2 -d '-')
    rt_grep_opts="-v -s"
else
    old_version=$(find ./ -maxdepth 1 -type d | grep rt | sort | tail -n 2 | head -n 1 | cut -f 2 -d '/' | cut -f 2- -d '-')
    rt_grep_opts="-s"
fi
new_version=$(find ./ -maxdepth 1 -type d | grep $rt_grep_opts rt | sort | tail -n 1 | cut -f 2 -d '/' | cut -f 2- -d '-')

function cleanup {
    keep_version=$1
    rt_grep_opts=$2
    prefix=$3
    old_versions=$(ls -d /usr/src/$prefix-* | grep $rt_grep_opts rt | grep -v $keep_version | xargs -I {} basename {} | cut -f 2- -d '-')
    if [ ${#old_versions[0]} -gt 0 ]
    then
        echo "Found old versions in /usr/src:"
        echo $old_versions
        echo
        echo "Press y to remove them, any other key to skip."
        echo "Files of those versions in /boot and /lib/modules will also be removed."
        read -n1 remove
        if test "X$remove" = "Xy"
        then
            echo
            for version in $old_versions
            do
                rm -rf /usr/src/linux-$version
                rm -rf /lib/modules/$version
                rm /boot/System.map-$version 2>/dev/null
                rm /boot/kernel-$version 2>/dev/null
                echo "Removed kernel version $version files."
            done
        fi
    else
        echo "Found nothing to clean up."
    fi
    echo
}

if test $old_version = $new_version
then
    echo "New kernel was not found."
    cd $cwd
    cleanup $new_version "$rt_grep_opts" $prefix
    echo "All done."
    read
    exit
fi

echo "Updating from kernel $old_version to $new_version."
echo "Press any key to continue, Ctrl-C to abort."
read

cp $prefix-$old_version/.config $prefix-$new_version/

cd $prefix-$new_version
make oldconfig
make
echo "Compiled kernel."
make modules_install
echo "Installed modules."

cp System.map /boot/System.map-$new_version
echo "Copied System.map."
cp arch/x86_64/boot/bzImage /boot/kernel-$new_version
echo "Copied kernel image."

if test "X$1" != "Xrt"
then
    cd ..
    rm linux
    ln -s $prefix-$new_version linux
    echo "Updated kernel symlink."
else
    echo "Using RT kernel, symlink is not updated."
fi

sed -i "s/$old_version/$new_version/g" /boot/grub/grub.conf
echo "Updated grub config."
echo

cd "$cwd"

cleanup $new_version "$rt_grep_opts" $prefix

echo All done.
read
