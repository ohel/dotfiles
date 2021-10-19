#!/bin/sh
# Start a Qemu-KVM virtual machine. Consider this script a template to copy per virtual machine.
# Assumes the client has drivers installed for the paravirtualized VirtIO Ethernet Adapter,
# VirtIO SCSI controller, and QXL video device.

img_name="${1:-"vm.img"}"
vm_name="${2:-"KVM"}"
net_id=${3:-10} # Used as the last number of static IP address of the guest, MAC address and VNC display.

vm_mem_mb=8192
vm_num_cores=4
vm_threads_per_core=1

audio=0 # Note: on modern Windows guests the audio emulation bugs so that there are cracks and pops all the time.
auto_network=1
auto_vnc=0
boot_from_cd=0
bridged_network=0

vm_bridge=vmbridge
net_bridge=netbridge
cdrom_image="image.iso"

if [ "$(which gvncviewer 2>/dev/null)" ]
then
    vncviewer="gvncviewer localhost:$net_id"
elif [ "$(which vncviewer 2>/dev/null)" ]
then
    vncviewer="vncviewer :$net_id"
fi

if [ "$bridged_network" = 1 ] && [ "$(brctl show $net_bridge 2>&1 | grep "\(No\)\|\(not \)")" ]
then
    echo "Set up the bridged network manually first."
    exit 1
fi

if [ "$(brctl show $vm_bridge 2>&1 | grep "\(No\)\|\(not \)")" ]
then
    if [ "$auto_network" = 0 ]
    then
        echo "The bridge $vm_bridge does not exist. Aborting..."
        exit 1
    fi
    ./vmnetwork.sh
fi

modprobe tun
modprobe kvm
if [ "$(lscpu | grep Intel)" ]
then
    modprobe kvm-intel
else
    modprobe kvm-amd
fi

pid=$(ps -ef | grep "qemu.*$vm_name" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if [ "$pid" ]
then
    echo $vm_name virtual machine is already running with PID: $pid
    echo "Press return to kill."
    read tmp
    kill $pid
    sleep 2
    echo "Press return to restart the virtual machine."
    read tmp
fi

dac=""
adc=""
soundhw=""
if [ "$audio" = 1 ]
then
    if [ "$(ps -e | grep pulseaudio)" ]
    then
        sound_params="QEMU_AUDIO_DRV=pa"
    else
        modprobe snd-aloop
        dac="hw:Loopback,0,4" # loop_vm_dac_in
        adc="hw:Loopback,1,5" # loop_vm_adc_out
        sound_params="QEMU_ALSA_DAC_DEV=$dac QEMU_ALSA_ADC_DEV=$adc"
    fi
    soundhw="-soundhw hda"
fi

bootstring="c"
[ "$boot_from_cd" = 1 ] && bootstring="d -cdrom $cdrom_image"

videohw="-vga std"
if [ ! "$(echo quit | qemu-system-x86_64 -vga qxl -machine none -nographic 2>&1 | grep QXL)" ]
then
    port=$net_id
    [ "$net_id" -lt 10 ] && port="0"$port
    videohw="-vga qxl \
        -device virtio-serial-pci \
        -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
        -chardev spicevmc,id=spicechannel0,name=vdagent \
        -spice port=600$port,addr=127.0.0.1,disable-ticketing"
fi

bridged_net_devices=""
[ "$bridged_network" = 1 ] && bridged_net_devices="\
-device virtio-net-pci,netdev=net"$net_id"_1 -netdev tap,id=net"$net_id"_1,br=$net_bridge,script=kvm_tap_netbridge.sh"

echo "Starting the virtual machine..."
env $sound_params qemu-system-x86_64 \
-vnc localhost:$net_id \
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
-device virtio-net-pci,netdev=net"$net_id"_0 -netdev tap,id=net"$net_id"_0,br=$vm_bridge,script=kvm_tap_vmbridge.sh \
-drive file="$img_name",if=virtio,format=raw \
$bridged_net_devices \
$soundhw \
$videohw \
-device ich9-usb-uhci1 \
-device ich9-usb-uhci2 \
-device ich9-usb-uhci3 \
-device ich9-usb-ehci1 \
-device usb-tablet \
-device nec-usb-xhci \

# Common workarounds and tweaks:
# * Fixes most problems and some BSODs in Windows, especially during setup:
# -cpu core2duo \
# * Required if VM hangs during POST until VNC connection is established:
# -no-kvm-irqchip \
# * To fix cursor position in Windows clients, use the usb-tablet device. It might help in VNC connections with other guests also:
# -device usb-tablet \
# * Pass a single USB port through to client (check bus and port with lsusb -t):
# -device usb-host,hostbus=1,hostport=1 \
#   * After Qemu version 2.10.50 (approximately), passed devices nowadays need to have a manually defined USB host controller. However, there is no need to define the "id", "bus" or "addr" parameters manually anymore, they are handled automatically. The USB device speed must also match the host controller speed: for example, a USB headset probably requires nec-usb-xhci.
#   * In short: first define the controller, then the device which should attach to it.
#   * The deprecated -usbdevice option implied the ich9-usb-uhci[123] and ich-9-usb-echi1 controllers.
# * The br parameter for netdev does not work, it always adds the tap device to first bridge found. Therefore we need to use scripts.

sleep 2

# The PID changes so we cannot use last PID.
pid=$(ps -ef | grep "qemu.*$vm_name" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if [ "$pid" ]
then
    renice +15 $pid
fi

if [ "$auto_vnc" = 1 ] && [ "$vncviewer" ]
then
    $vncviewer &
fi
