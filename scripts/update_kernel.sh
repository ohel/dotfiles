#!/bin/bash
# Update a kernel by compiling a new kernel if it exists, using old config file as base. Old version is the one symlinked to /usr/src/linux.
# The script copies the necessary files to the boot partition.
# If dracut is found, a new initramfs image is created using it in hostonly mode.
#
# If $1 == grub or $2 == grub, grub.conf and /boot/boot is updated also.
# If $1 or $2 is something else, it will be used as the kernel source directory instead. Nothing will be removed, just compiled and copied.
#
# By default, the script works by updating an <EFI system partition>/EFI which is assumed to be mounted to /boot/EFI.
# Files are copied to /boot/EFI/linux, and config file /boot/EFI/BOOT/refind.conf is updated for new kernel versions.

# Kernel source directory prefix for automatic version detection. Directories with other prefixes are skipped.
prefix="linux"
efi_dest_dir=/boot/EFI

# A system specific boot backup script, such as an ESP backup or copying via boot symlink, if cleanup was OK.
boot_backup_script=/opt/boot_backup.sh

cwd="$(pwd)"
use_grub=""
src_dir="$1"
[ "$1" == "grub" ] && use_grub=1 && src_dir="$2"
[ "$2" == "grub" ] && use_grub=1

use_dracut=""
$(which dracut > /dev/null 2>&1) && use_dracut=1

if [ "$(echo $HOME)" != "/root" ]
then
    echo "You must be root to update kernel."
    read
    exit 1
fi

if [ "$src_dir" ] && [ ! -e $src_dir ]
then
    echo "Source dir $src_dir does not exist, aborting."
    read
    exit 1
fi

if [ ! "$src_dir" ] && [ ! -e /usr/src/linux ]
then
    echo "The symbolic link /usr/src/linux does not exist, aborting."
    read
    exit 1
fi

if [ ! "$use_grub" ]
then
    # Mounts all fstab entries with /efi/ in them.
    for efi_mount_point in $(cat /etc/fstab | grep "\/efi\(\/\S*\)\?\s" | grep -o "\/\S*")
    do
        [ "$(mount | grep " $efi_mount_point ")" ] || mount $efi_mount_point
    done
    if [ ! -e $efi_dest_dir/linux ]
    then
        echo "$efi_dest_dir/linux does not exist, aborting."
        read
        exit 1
    fi
fi

function cleanup {
    keep_version=$1
    prefix=$2
    efi_dest_dir=$3
    old_versions=($(ls -d /usr/src/$prefix-* | grep -v $keep_version | xargs -I {} basename {} | cut -f 2- -d '-'))
    if [ ${#old_versions[@]} -gt 0 ]
    then
        echo "Found old versions in /usr/src:"
        echo ${old_versions[@]}
        echo
        echo "Press y to remove them, any other key to skip."
        echo "Files of those versions in /boot and /lib/modules will also be removed."
        read -n1 remove
        if [ "$remove" == "y" ]
        then
            echo
            for version in ${old_versions[@]}
            do
                rm -rf /usr/src/linux-$version
                rm -rf /lib/modules/$version

                rm /boot/System.map-$version 2>/dev/null
                rm /boot/kernel-$version 2>/dev/null
                rm /boot/initramfs-$version.img 2>/dev/null
                if [ "$efi_dest_dir" ]
                then
                    rm $efi_dest_dir/linux/kernel-$version 2>/dev/null
                    rm $efi_dest_dir/linux/initramfs-$version.img 2>/dev/null
                fi
                echo "Removed kernel version $version files."
            done
            return 0
        fi
    else
        echo "Found nothing to clean up."
    fi
    echo
    return 1
}

if [ "$src_dir" ]
then
    cd $src_dir
    make oldconfig
else
    cd /usr/src
    old_version=$(readlink linux | cut -f 2 -d '-')
    new_version=$(ls -v1 --file-type | grep '/' | cut -f 1 -d '/' | grep "^$prefix" | tail -n 1 | cut -f 2- -d '-')

    if [ "$old_version" == "$new_version" ]
    then
        echo "New kernel was not found."
        cd $cwd
        cleanup $new_version $prefix $efi_dest_dir
        [ $? -eq 0 ] && [ -e $boot_backup_script ] && $boot_backup_script

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
    echo "Press return to continue, Ctrl-C to abort."
    read

    cp $prefix-$old_version/.config $prefix-$new_version/

    cd $prefix-$new_version
    make oldconfig
fi

num_threads=$(echo 1.99+$(grep "processor.*:" /proc/cpuinfo | tail -n 1 | cut -f 2 -d ':')*0.75 | bc | cut -f 1 -d '.')
make -j $num_threads

if [ ! -e arch/x86_64/boot/bzImage ]
then
    echo "Unable to find bzImage. Aborting."
    read
    exit 1
fi

echo "Compiled kernel."
make modules_install
echo "Installed modules."

[ ! "$new_version" ] && new_version=$(cat include/config/kernel.release)
[ ! "$new_version" ] && echo "Error, new version not defined." && exit 1

cp System.map /boot/System.map-$new_version
echo "Copied System.map to /boot."
cp arch/x86_64/boot/bzImage /boot/kernel-$new_version
echo "Copied kernel image to /boot."

if [ "$use_dracut" ]
then
    echo "Creating initramfs using dracut..."
    dracut --hostonly --kver $new_version > /dev/null 2>&1
    if [ ! -e /boot/initramfs-$new_version.img ]
    then
        echo "Error creating initramfs image. Aborting."
        read
        exit 1
    fi
fi

if [ ! "$use_grub" ]
then
    cp /boot/kernel-$new_version $efi_dest_dir/linux
    echo "Copied kernel image to ESP."
    cp /boot/initramfs-$new_version.img $efi_dest_dir/linux
    echo "Copied initramfs image to ESP."
fi

if [ ! "$src_dir" ]
then
    cd ..
    rm linux
    ln -s $prefix-$new_version linux
    echo "Updated kernel symlink."

    if [ "$use_grub" ]
    then
        sed -i "s/$old_version/$new_version/g" /boot/grub/grub.conf
        echo "Updated grub config."
    else
        sed -i "s/$old_version/$new_version/g" $efi_dest_dir/BOOT/refind.conf
        echo "Updated refind config."
    fi
    echo

    cd "$cwd"

    cleanup $new_version $prefix $efi_dest_dir
    [ $? -eq 0 ] && [ -e $boot_backup_script ] && $boot_backup_script
fi

echo All done.
read
