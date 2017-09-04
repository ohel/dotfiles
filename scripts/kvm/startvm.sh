#!/bin/bash
# Start a Qemu-KVM virtual machine. Consider this script a template to copy per virtual machine.

windows_guest=0
boot_from_cd=0
audio=1 # not supported on Windows guests
auto_vnc=0
img_name="${1:-"xubuntu.img"}"
vm_name="${2:-"Xubuntu"}"
net_id=${3:-10} # used as the last number of static IP address of the guest, MAC address and VNC display

vm_bridge=vmbridge
cdrom_image="image.iso"

if test "X$(which gvncviewer)" != "X"
then
    vncviewer="gvncviewer localhost:$net_id"
elif test "X$(which vncviewer)" != "X"
then
    vncviewer="vncviewer :$net_id"
fi

if test "X$(brctl show $vm_bridge 2>&1 | grep No)" != "X"
then
    echo "The bridge $vm_bridge does not exist. Aborting..."
    exit
fi

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
if test $audio = 1 && test $windows_guest = 0
then
    modprobe snd-aloop
    dac="hw:Loopback,0,4" # loop_vm_dac_in
    adc="hw:Loopback,1,5" # loop_vm_adc_out
    soundhw="-soundhw hda"
fi

bootstring="c"
if test $boot_from_cd = 1
then
    bootstring="d -cdrom $cdrom_image"
fi

if test $windows_guest = 1
then
    # Required for Windows guests.
    cursor_fix="-usbdevice tablet"
fi

echo "Starting the virtual machine..."
env QEMU_ALSA_DAC_DEV=$dac QEMU_ALSA_ADC_DEV=$adc qemu-system-x86_64 $soundhw $cursor_fix \
-daemonize \
-name "$vm_name" \
-boot $bootstring \
-machine q35,accel=kvm \
-cpu host \
-smp cores=2,threads=1,sockets=1 \
-m 4096 \
-k fi \
-display none \
-net nic,model=virtio,macaddr="00:00:00:00:00:$net_id",name=eth0 \
-net tap,script="kvm_net_up.sh" \
-drive file="$img_name",if=virtio,format=raw \
-vnc :$net_id

# Common workarounds and tweaks:
# -cpu core2duo: fixes most problems and some BSODs in Windows, especially during setup
# -no-kvm-irqchip: required if VM hangs during POST until VNC connection is established
# -device usb-host,hostbus=1,hostport=1: check bus and port with lsusb -t to pass a single USB port through to client
# -device usb-ehci,id=usb,bus=pcie.0,addr=0x4: needed if passing a USB port with device detached (addr seems arbitrary)

sleep 2

# The PID changes so we cannot use last PID.
pid=$(ps -ef | grep "qemu.*$vm_name" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if test "X$pid" != "X"
then
    renice +15 $pid
fi

if test $auto_vnc = 1 && "X$vncviewer" != "X"
then
    $vncviewer &
fi
