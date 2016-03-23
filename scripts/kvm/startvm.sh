#!/bin/bash
audio=1
boot_other=0
name="Xubuntu"
img_name="xubuntu.img"

modprobe kvm
modprobe kvm-intel
modprobe tun

pid=$(ps -ef | grep qemu.*$name | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if test "X$pid" != "X"
then
 echo $name virtual machine is already running with PID: $pid
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
  dac="hw:Loopback,0,4" # loop_vm_dac_in
  adc="hw:Loopback,1,5" # loop_vm_adc_out
  soundhw="-soundhw hda"
fi

bootstring="c"
if [ $boot_other -eq 1 ]
then
    bootstring="d -cdrom /opt/virtualmachines/image.iso"
fi

/bin/env QEMU_ALSA_DAC_DEV=$dac QEMU_ALSA_ADC_DEV=$adc qemu-system-x86_64 $soundhw -daemonize \
-name "$name" \
-boot $bootstring \
-machine q35,accel=kvm \
-cpu core2duo \
-smp 2 \
-m 4096 \
-k fi \
-display none \
-net nic,model=virtio,macaddr="00:00:00:00:00:01",name=eth0 \
-net tap,script="kvm_net_up.sh" \
-drive file="$img_name",if=virtio,format=raw \
-no-kvm-irqchip \
-vnc :1
# -no-kvm-irqchip: required if VM hangs during POST until VNC connection is established
# -usbdevice tablet: required for Windows guests

