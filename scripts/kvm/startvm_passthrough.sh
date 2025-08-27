#!/usr/bin/sh
# Open KVM with GPU passthrough enabled. Also start Input Leap for software keyboard-mouse switch/extension if it is not running already.
! ps -e | grep -q "input-leaps$" && /usr/bin/flatpak run --branch=master --arch=x86_64 --command=input-leap io.github.input_leap.InputLeap &
cd /opt/virtualmachines
sudo ./startvm.sh 1
