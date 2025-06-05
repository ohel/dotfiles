#!/usr/bin/sh
# This script starts up xboxdrv for Saitek Cyborg Rumble Pad, creates symlink and sets read permission to new evdev.
# Need to run as root.

ls -1 /dev/input/event* > /dev/shm/xboxdrv_oldevdev.txt

configfile="/opt/xboxdrv/current_saitek"
[ -e $configfile ] && config_file_opts="-c $configfile"
/usr/bin/xboxdrv --silent --device-by-path $1:$2 --type xbox360 --led 6 $config_file_fjopts >/dev/null 2>&1 &

# Wait for xboxdrv to create the js device.
sleep 1
[ ! "$(find /dev/input/ -maxdepth 1 -name "js*" | head -1)" ] && exit 1

# Create symlink for the just created joystick device.
ln -sf $(ls -1 --sort=t /dev/input/js* | head -n 1) /dev/input/saitek-xbox360-gamepad

# Find new evdev by comparing old evdev list with new one.
ls -1 /dev/input/event* > /dev/shm/xboxdrv_newevdev.txt
newevdev=$(comm -3 /dev/shm/xboxdrv_oldevdev.txt /dev/shm/xboxdrv_newevdev.txt | tr -d [:blank:])
[ "$newevdev" ] && chmod a+r $newevdev

rm /dev/shm/xboxdrv_oldevdev.txt
rm /dev/shm/xboxdrv_newevdev.txt
