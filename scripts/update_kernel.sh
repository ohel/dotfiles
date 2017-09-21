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
    grep_opts="-v"
else
    old_version=$(find ./ -maxdepth 1 -type d | grep rt | sort | tail -n 2 | head -n 1 | cut -f 2 -d '/' | cut -f 2 -d '-')
fi
new_version=$(find ./ -maxdepth 1 -type d | grep $grep_opts rt | sort | tail -n 1 | cut -f 2 -d '/' | cut -f 2 -d '-')

if test $old_version = $new_version
then
    echo "New kernel was not found, aborting."
    cd $cwd
    exit
fi

echo "Updating from kernel $old_version to $new_version."
echo "Press any key to continue, Ctrl-C to abort."
read

cp $prefix-$old_version/.config $prefix-$new_version/
echo "Config file copied."

cd $prefix-$new_version
make oldconfig
echo "Config file prepared. Starting to compile."
make
echo "Done compiling. Installing modules..."
make modules_install

echo "Copying System.map..."
cp System.map /boot/System.map-$new_version
echo "Copying kernel image..."
cp arch/x86_64/boot/bzImage /boot/kernel-$new_version

if test "X$1" != "Xrt"
then
    echo "Updating kernel symlink..."
    cd ..
    rm linux
    ln -s $prefix-$new_version linux
else
    echo "Using RT kernel, symlink is not updated."
fi

echo "Updating grub config..."
sed -i "s/$old_version/$new_version/g" /boot/grub/grub.conf

cd "$cwd"

echo "All done."
echo "Existing kernel modules in /lib/modules:"
ls /lib/modules/
echo "Existing kernels in /boot:"
ls /boot/kernel*
echo
