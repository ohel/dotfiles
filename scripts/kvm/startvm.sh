#!/bin/bash
audio=1
cdrom_image="/opt/virtualmachines/image.iso"
cdrom_image="" # if not empty, cdrom_image is booted instead
vm_name="Xubuntu"
img_name="xubuntu.img"
net_id=10 # used as the static IP address in the guest, MAC address and VNC display
vncviewer="gvncviewer localhost:$net_id"

modprobe kvm
modprobe kvm-intel
modprobe tun

pid=$(ps -ef | grep "qemu.*$vm_name" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if test "X$pid" != "X"
then
    echo $vm_name virtual machine is already running with PID: $pid
    echo "Press return to kill."
    read
    kill $pid
    sleep 2
    echo "Press return to restart the virtual machine."
    read
fi

dac=""
adc=""
soundhw=""
if test "X$1" == "Xaudio" || test "$audio" == 1
then
    modprobe snd-aloop
    dac="hw:Loopback,0,4" # loop_vm_dac_in
    adc="hw:Loopback,1,5" # loop_vm_adc_out
    soundhw="-soundhw hda"
fi

bootstring="c"
if test "X$cdrom_image" != "X"
then
    bootstring="d -cdrom $cdrom_image"
fi

/bin/env QEMU_ALSA_DAC_DEV=$dac QEMU_ALSA_ADC_DEV=$adc qemu-system-x86_64 $soundhw -daemonize \
-name "$vm_name" \
-boot $bootstring \
-machine q35,accel=kvm \
-cpu core2duo \
-smp 2 \
-m 4096 \
-k fi \
-display none \
-net nic,model=virtio,macaddr="00:00:00:00:00:$net_id",name=eth0 \
-net tap,script="kvm_net_up.sh" \
-drive file="$img_name",if=virtio,format=raw \
-vnc :$net_id
# -no-kvm-irqchip: required if VM hangs during POST until VNC connection is established
# -usbdevice tablet: required for Windows guests

if test "X$vncviewer" != "X"
then
    sleep 1
    $vncviewer &
fi

