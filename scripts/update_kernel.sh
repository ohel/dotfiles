#!/bin/bash
# Update a kernel by compiling a new kernel if it exists, using old config file as base.
# Copies the necessary files to the boot partition and updates grub.conf.
# If $1 == rt, realtime kernel is updated instead.

prefix="linux"

cwd="$(pwd)"

if [ "$(echo $HOME)" != "/root" ]
then
    echo "You must be root to update kernel."
    read
    exit 1
fi

if [ ! -e /usr/src/linux ]
then
    echo "The symbolic link /usr/src/linux does not exist, aborting."
    read
    exit 1
fi

cd /usr/src
if [ "$1" == "rt" ]
then
    old_version=$(ls -v1 --file-type | grep '/' | cut -f 1 -d '/' | grep rt | tail -n 2 | head -n 1 | cut -f 2- -d '-')
    rt_grep_opts="-s"
else
    old_version=$(readlink linux | cut -f 2 -d '-')
    rt_grep_opts="-v -s"
fi
new_version=$(ls -v1 --file-type | grep '/' | cut -f 1 -d '/' | grep $rt_grep_opts rt | tail -n 1 | cut -f 2- -d '-')

function cleanup {
    keep_version=$1
    rt_grep_opts=$2
    prefix=$3
    old_versions=($(ls -d /usr/src/$prefix-* | grep $rt_grep_opts rt | grep -v $keep_version | xargs -I {} basename {} | cut -f 2- -d '-'))
    if [ ${#old_versions[@]} -gt 0 ]
    then
        echo "Found old versions in /usr/src:"
        echo $old_versions
        echo
        echo "Press y to remove them, any other key to skip."
        echo "Files of those versions in /boot and /lib/modules will also be removed."
        read -n1 remove
        if [ "$remove" == "y" ]
        then
            echo
            for version in $old_versions
            do
                rm -rf /usr/src/linux-$version
                rm -rf /lib/modules/$version

                # For some reason RT kernels in /lib/modules are named like
                # <version>-rt-rt<revision>, not like <version>-rt<revision>.
                rt_version=$(echo $version | grep rt | sed "s/-rt/-rt-rt/")
                [ "$rt_version" ] && rm -rf /lib/modules/$rt_version

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

if [ "$old_version" == "$new_version" ]
then
    echo "New kernel was not found."
    cd $cwd
    cleanup $new_version "$rt_grep_opts" $prefix
    echo "All done."
    read
    exit 0
fi

if [ ! -e $prefix-$old_version/.config ]
then
    echo "The config file for the old version could not be found, aborting."
    read
    exit 1
fi

echo "Updating from kernel $old_version to $new_version."
echo "Press any key to continue, Ctrl-C to abort."
read

cp $prefix-$old_version/.config $prefix-$new_version/

cd $prefix-$new_version
make oldconfig
make

if [ ! -e arch/x86_64/boot/bzImage ]
then
    echo "Unable to find bzImage. Aborting."
    read
    exit 1
fi

echo "Compiled kernel."
make modules_install
echo "Installed modules."

cp System.map /boot/System.map-$new_version
echo "Copied System.map."
cp arch/x86_64/boot/bzImage /boot/kernel-$new_version
echo "Copied kernel image."

if [ "$1" != "rt" ]
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
