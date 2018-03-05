#!/bin/bash
# Start a Qemu-KVM virtual machine. Consider this script a template to copy per virtual machine.
# Assumes the client has drivers installed for the paravirtualized VirtIO Ethernet Adapter,
# VirtIO SCSI controller, and QXL video device.

img_name="${1:-"vm.img"}"
vm_name="${2:-"KVM"}"
net_id=${3:-10} # used as the last number of static IP address of the guest, MAC address and VNC display

vm_mem_mb=8192
vm_num_cores=2
vm_threads_per_core=1

windows_guest=1
audio=1 # not supported (ignored) on Windows guests
auto_vm_bridge=1
auto_vnc=0
boot_from_cd=0

vm_bridge=vmbridge
cdrom_image="image.iso"

if test "X$(which gvncviewer 2>/dev/null)" != "X"
then
    vncviewer="gvncviewer localhost:$net_id"
elif test "X$(which vncviewer 2>/dev/null)" != "X"
then
    vncviewer="vncviewer :$net_id"
fi

if test "X$(brctl show $vm_bridge 2>&1 | grep No)" != "X"
then
    if test $auto_vm_bridge = 0
    then
        echo "The bridge $vm_bridge does not exist. Aborting..."
        exit
    fi
    ./vmnetwork_up.sh
fi

modprobe tun
modprobe kvm
if test "X$(lscpu | grep Intel)" != "X"
then
    modprobe kvm-intel
else
    modprobe kvm-amd
fi

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
    if test "X$(ps -e | grep pulseaudio)" = "X"
    then
        modprobe snd-aloop
        dac="hw:Loopback,0,4" # loop_vm_dac_in
        adc="hw:Loopback,1,5" # loop_vm_adc_out
        sound_params="QEMU_ALSA_DAC_DEV=$dac QEMU_ALSA_ADC_DEV=$adc"
    else
        sound_params="QEMU_AUDIO_DRV=pa"
    fi
    soundhw="-soundhw hda"
fi

bootstring="c"
if test $boot_from_cd = 1
then
    bootstring="d -cdrom $cdrom_image"
fi

vga=std
if test "X$(echo quit | qemu-system-x86_64 -vga qxl -machine none -nographic 2>&1 | grep QXL)" = "X"
then
    vga=qxl
fi

echo "Starting the virtual machine..."
env $sound_params qemu-system-x86_64 $soundhw \
-daemonize \
-enable-kvm \
-name "$vm_name" \
-boot $bootstring \
-machine q35,accel=kvm \
-cpu host \
-smp cores=$vm_num_cores,threads=$vm_threads_per_core,sockets=1 \
-m $vm_mem_mb \
-k fi \
-display none \
-vga $vga \
-net nic,model=virtio,macaddr="00:00:00:00:00:$net_id",name=eth0 \
-net tap,script="kvm_net_up.sh" \
-drive file="$img_name",if=virtio,format=raw \
-device ich9-usb-uhci1 \
-device ich9-usb-uhci2 \
-device ich9-usb-uhci3 \
-device ich9-usb-ehci1 \
-device usb-tablet \
-device nec-usb-xhci \
-vnc :$net_id

# Common workarounds and tweaks:
# * Fixes most problems and some BSODs in Windows, especially during setup:
# -cpu core2duo \
# * Required if VM hangs during POST until VNC connection is established:
# -no-kvm-irqchip \
# * To fix cursor position in Windows clients, use the usb-tablet device. It might help in VNC connections with other guests also:
# -device usb-tablet \
# * Pass a single USB port through to client (check bus and port with lsusb -t):
# -device usb-host,hostbus=1,hostport=1 \
#   * After Qemu version 2.10.50 (approximately), passed devices nowadays need to have a manually defined USB host controller. However, there is no need to define the "id", "bus" or "addr" parameters manually anymore. They are handled automatically. The USB device speed must also match the host controller speed: for example, a USB headset probably requires nec-usb-xhci.
#   * In short: first define the controller, then the device which should attach to it.
#   * The deprecated -usbdevice option implied the ich9-usb-uhci[123] and ich-9-usb-echi1 controllers.

# Contents of kvm_net_up.sh:
#!/bin/sh
# Argument $1 will be the name of the interface, e.g. tap0
# /sbin/brctl addif vmbridge $1 && /bin/ip link set $1 up

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
