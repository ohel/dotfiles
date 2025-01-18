#!/usr/bin/bash
# Update a kernel by compiling a new kernel if it exists, using old config file from currently running kernel as base.
# If dracut is found, a new initramfs image is created using it.
# If /opt/mok/mok.key and /opt/mok/mok.crt exist, the kernel is signed with sbsign.
# The script copies the necessary files to the boot partition.
#
# By default, in rEFInd mode, the script works by updating the directory <EFI system partition>/EFI which is assumed to be mounted to $EFI_DEST_DIR.
# Boot files are copied to $EFI_DEST_DIR/linux, and all config files named "refind.conf" under $EFI_DEST_DIR are updated to point to the kernel release.
# It is assumed there are only two versions in the config files: the current one, and a backup, identified with $BACKUP_MENUENTRY_IDENTIFIER in its menuentry.
# The backup release will be made to point to the current running release.
# The backup release menuentry disabled state will be toggled based on whether there is only a single kernel after cleanup.
#
# In grub mode, instead of rEFInd configs and EFI directory, grub.conf and /boot/boot are updated.
#
# If $1 or $2 is "grub", grub mode is used.
# If $1 or $2 is "hostonly", dracut is run using hostonly mode.
# If $1 or $2 (or $3) is something else, it will be used as the kernel source directory instead. Nothing will be removed, just compiled and copied. The config files (refind.conf and grub.conf) will not be updated, either. This may be used for example to recompile a currently running kernel version with an updated .config file.

# Kernel source directory prefix for automatic release detection. Directories with other prefixes are skipped.
PREFIX="linux"

# Mount point for <EFI system partition>/EFI directory.
EFI_DEST_DIR=/boot/EFI

# An optional system specific boot backup script such as an ESP backup.
BOOT_BACKUP_SCRIPT=/opt/boot_backup.sh

# For rEFInd config files, identify backup release menuentry with this string.
BACKUP_MENUENTRY_IDENTIFIER="backup release"

cwd="$(pwd)"
use_grub=""
hostonly_mode=""
user_given_src_dir="$1"
[ "$1" == "grub" ] && use_grub=yes && user_given_src_dir="$2"
[ "$2" == "grub" ] && use_grub=yes
[ "$1" == "hostonly" ] && hostonly_mode="--hostonly" && user_given_src_dir="$2"
[ "$2" == "hostonly" ] && hostonly_mode="--hostonly"
[ "$use_grub" ] && [ "$hostonly_mode" ] && user_given_src_dir="$3"

use_dracut=""
$(which dracut >/dev/null 2>&1) && use_dracut=1

#### GENERAL CHECKS #####

if [ "$(echo $HOME)" != "/root" ]
then
    echo "You must be root to update kernel."
    read
    exit 1
fi

if [ "$user_given_src_dir" ] && [ ! -e $user_given_src_dir ]
then
    echo "Source dir $user_given_src_dir does not exist, aborting."
    read
    exit 1
fi

if [ ! "$use_grub" ]
then
    # Mounts all fstab entries with /efi/ in them.
    for efi_mount_point in $(grep "/efi\(/\S*\)\?\s" /etc/fstab | grep -o "/\S*")
    do
        [ "$(mount | grep " $efi_mount_point ")" ] || mount $efi_mount_point
    done
    if [ ! -e $EFI_DEST_DIR/linux ]
    then
        echo "$EFI_DEST_DIR/linux does not exist, aborting."
        read
        exit 1
    fi
fi

# Some applications require read access to the compiled kernel files.
umask 0022

#### CLEANUP FUNCTION #####

function cleanup {
    [ ! "$PREFIX" ] || [ ! "$EFI_DEST_DIR" ] || [ ! "$BACKUP_MENUENTRY_IDENTIFIER" ] && echo "Error: missing definitions." && return 1

    current_release=$(uname -r)
    keep_release=${1:-$current_release}

    current_releases=($(ls -d /usr/src/$PREFIX-* | grep -v $keep_release | xargs -I {} basename {} | cut -f 2- -d '-'))
    if [ ${#current_releases[@]} -eq 0 ]
    then
        echo "Found nothing to clean up."
        echo "Run backup scripts? Press y to run, any other key to skip."
        read -n1 runbackup
        echo
        [ "$runbackup" != "y" ] && return 1
        return 0
    fi

    echo "Found old releases in /usr/src:"
    echo ${current_releases[@]}
    echo
    if [ "$keep_release" != "$current_release" ]
    then
        echo "Old releases can be removed by this script by booting the newest kernel."
        echo "Press return to continue."
        echo
        read
    else
        echo "Remove old releases? Press y to remove, any other key to skip."
        echo "Files of those releases in /boot and /lib/modules will also be removed."
        read -n1 remove
        echo
    fi

    [ "$remove" != "y" ] && return 1

    echo
    for release in ${current_releases[@]}
    do
        rm -rf /usr/src/linux-$release
        rm -rf /lib/modules/$release

        rm /boot/System.map-$release 2>/dev/null
        rm /boot/kernel-$release 2>/dev/null
        rm /boot/initramfs-$release.img 2>/dev/null

        rm $EFI_DEST_DIR/linux/kernel-$release 2>/dev/null
        rm $EFI_DEST_DIR/linux/initramfs-$release.img 2>/dev/null

        echo "Removed kernel release $release files."
    done
    echo

    for config_file in $(find $EFI_DEST_DIR/ -name refind.conf)
    do
        backup_begin=$(grep -n "$BACKUP_MENUENTRY_IDENTIFIER" $config_file | cut -f 1 -d ':')
        backup_end=$(grep -n "menuentry" $config_file | grep -A 1 "^$backup_begin" | tail -n 1 | cut -f 1 -d ':')
        [ ! $backup_end ] && backup_end=$(wc -l $config_file) # Backup entry is the last menuentry.
        [ "$backup_begin" ] && sed -i "$backup_begin,$backup_end s/# *disabled/disabled/" $config_file
    done

    return 0
}

#### USER-DEFINED RELEASE TO COMPILE #####

if [ "$user_given_src_dir" ]
then
    cd $user_given_src_dir
    make oldconfig
else

    #### AUTO-DETECT NEW RELEASE TO COMPILE #####

    cd /usr/src
    current_release=$(uname -r)
    new_release=$(ls -v1 --file-type | grep '/' | cut -f 1 -d '/' | grep "^$PREFIX" | tail -n 1 | cut -f 2- -d '-')

    if [ "$current_release" == "$new_release" ]
    then
        echo "No new kernel releases found."
        cd $cwd
        cleanup $current_release
        [ $? -eq 0 ] && [ -e $BOOT_BACKUP_SCRIPT ] && $BOOT_BACKUP_SCRIPT

        echo "All done."
        read
        exit 0
    fi

    if [ ! -e $PREFIX-$current_release/.config ]
    then
        echo "The config file for the old release could not be found, aborting."
        read
        exit 1
    fi

    echo "Updating from kernel $current_release to $new_release."
    echo "Press return to continue, Ctrl-C to abort."
    read

    copyconfig="yes"
    if [ -e $PREFIX-$new_release/.config ]
    then
        echo "Overwrite $new_release/.config? Press y to overwrite, any other key to skip."
        read -n1 overwrite
        echo
        [ "$overwrite" != "y" ] && copyconfig=""
    fi

    [ "$copyconfig" ] && cp $PREFIX-$current_release/.config $PREFIX-$new_release/

    cd $PREFIX-$new_release
    make oldconfig
fi

#### COMPILE AND COPY KERNEL, INSTALL MODULES #####

num_threads=$(echo 1.99+$(grep "processor.*:" /proc/cpuinfo | tail -n 1 | cut -f 2 -d ':')*0.75 | bc | cut -f 1 -d '.')
make -j $num_threads

if [ ! -e arch/x86_64/boot/bzImage ]
then
    echo "Unable to find bzImage. Aborting."
    read
    exit 1
fi

echo "Compiled kernel."

if [ -e /opt/mok/mok.key ] && [ -e /opt/mok/mok.crt ]
then
    if [ ! "$(which sbsign 2>/dev/null)" ]
    then
        echo "Unable to find sbsign. Aborting."
        read
        exit 1
    fi
    sbsign --key /opt/mok/mok.key --cert /opt/mok/mok.crt --output arch/x86_64/boot/bzImage arch/x86_64/boot/bzImage
    echo "Signed kernel using MOK."
fi

make modules_install
echo "Installed modules."

[ ! "$new_release" ] && new_release=$(cat include/config/kernel.release)
[ ! "$new_release" ] && echo "Error, new release not defined." && exit 1

cp System.map /boot/System.map-$new_release
echo "Copied System.map to /boot."
cp arch/x86_64/boot/bzImage /boot/kernel-$new_release
echo "Copied kernel image to /boot."

#### CREATE AND COPY INITRAMFS #####

if [ "$use_dracut" ]
then
    echo "Creating initramfs using dracut..."
    dracut $hostonly_mode --kver $new_release --force
    if [ ! -e /boot/initramfs-$new_release.img ]
    then
        echo "Error creating initramfs image. Aborting."
        read
        exit 1
    fi
fi

if [ ! "$use_grub" ]
then
    cp /boot/kernel-$new_release $EFI_DEST_DIR/linux
    echo "Copied kernel image to ESP."
    cp /boot/initramfs-$new_release.img $EFI_DEST_DIR/linux
    echo "Copied initramfs image to ESP."
fi

#### UPDATE CONFIG FILES #####

function update_refind_config {
    [ ! "$1" ] || [ ! "$2" ] || [ ! "$BACKUP_MENUENTRY_IDENTIFIER" ] && echo "Error: missing definitions." && return 1

    config_file=$1
    new_release=$2
    current_release=$(uname -r)
    sed -i "s/\(\(kernel\)\|\(initramfs\)\)-[2-9]\.[0-9]*\.[0-9]*/\1-$new_release/g" $config_file

    backup_begin=$(grep -n "$BACKUP_MENUENTRY_IDENTIFIER" $config_file | cut -f 1 -d ':')
    backup_end=$(grep -n "menuentry" $config_file | grep -A 1 "^$backup_begin" | tail -n 1 | cut -f 1 -d ':')
    [ ! $backup_end ] && backup_end=$(wc -l $config_file) # Backup entry is the last menuentry.
    if [ "$backup_begin" ]
    then
        sed -i "$backup_begin,$backup_end s/\(\(kernel\)\|\(initramfs\)\)-[2-9]\.[0-9]*\.[0-9]*/\1-$current_release/g" $config_file
        sed -i "$backup_begin,$backup_end s/\(^ *\)disabled/\1# disabled/" $config_file
    fi
}

if [ ! "$user_given_src_dir" ]
then
    cd ..
    rm linux
    ln -s $PREFIX-$new_release linux
    echo "Updated kernel symlink."

    if [ "$use_grub" ]
    then
        sed -i "s/$current_release/$new_release/g" /boot/grub/grub.conf
        echo "Updated grub config."
    else
        for config_file in $(find $EFI_DEST_DIR/ -name refind.conf)
        do
            update_refind_config $config_file $new_release
        done
        echo "Updated rEFInd config files:"
        find $EFI_DEST_DIR/ -name refind.conf
    fi
    echo

    cd "$cwd"

    cleanup $new_release
    [ $? -eq 0 ] && [ -e $BOOT_BACKUP_SCRIPT ] && $BOOT_BACKUP_SCRIPT
fi

echo All done.
read
