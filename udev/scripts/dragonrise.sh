#!/bin/sh
# A script for udev rule to run when adding a Drangonrise gamepad.
# It runs xboxdrv for the gamepad and symlinks the extra joystick device created by xboxdrv.
# Need to run as root.
configfile=/opt/xboxdrv/current_dragonrise

[ -e $configfile ] && opts="-c $configfile"

ls -1 /dev/input/event* > /dev/shm/xboxdrv_oldevdev.txt
/usr/bin/xboxdrv --evdev /dev/input/dragonrise-evdev --evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_RX=x2,ABS_RZ=y2,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y --evdev-keymap BTN_TRIGGER=a,BTN_THUMB=b,BTN_THUMB2=x,BTN_TOP=y,BTN_TOP2=back,BTN_PINKIE=start,BTN_BASE=lb,BTN_BASE2=rb,BTN_BASE3=lt,BTN_BASE4=rt,BTN_BASE5=tl,BTN_BASE6=tr --axismap -Y1=Y1 --trigger-as-button --device-name xboxdrv-dragonrise --force-feedback --dpad-as-button --silent $opts >/dev/null 2>&1 &

# Wait for xboxdrv to create the js device.
sleep 1
[ ! "$(find /dev/input/ -maxdepth 1 -name "js*" | head -1)" ] && exit 1

ln -sf $(ls -1 --sort=t /dev/input/js* | head -n 1) /dev/input/dragonrise-gamepad
ls -1 /dev/input/event* > /dev/shm/xboxdrv_newevdev.txt

newevdev=$(comm -3 /dev/shm/xboxdrv_oldevdev.txt /dev/shm/xboxdrv_newevdev.txt | tr -d [:blank:])
[ "$newevdev" ] && chmod a+r $newevdev

rm /dev/shm/xboxdrv_oldevdev.txt
rm /dev/shm/xboxdrv_newevdev.txt
