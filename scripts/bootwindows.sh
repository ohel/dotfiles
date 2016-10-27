#!/bin/bash
# Boot to Windows using a legacy GRUB hack (the grub default selection points to a Windows drive).

cp /boot/grub/default1 /boot/grub/default
sudo shutdown -r now

