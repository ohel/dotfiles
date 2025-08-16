#!/usr/bin/sh
# Start a Qemu-KVM virtual machine. Consider this script a template to copy per virtual machine.
# Assumes the client has drivers installed for the paravirtualized VirtIO Ethernet Adapter,
# VirtIO SCSI controller, and QXL video device.
# There's two parameters: passthrough and bridged_network. 0 disables (default), 1 enables.

img_name="vm.img"
vm_name="KVM"
net_id=10 # Used as the last number of static IP address of the guest, MAC address and VNC display.

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

vm_mem_mb=8192
vm_num_cores=4
vm_threads_per_core=1

audio=0
auto_setup_network=1
auto_start_vnc=0
boot_from_cd=0
boot_menu=0
bridged_network=${2:-0}
passthrough=${1:-0}
tpm=0
uefi=1

# If using too old OVMF files, some keys are required to be enrolled for secure boot.
# Use /usr/share/edk2-ovmf/UefiShell.iso as cdrom_image to boot and do:
#   Shell> fs0:
#   FS0:\> EnrollDefaultKeys.efi
#   FS0:\> reset
# If the file is not .iso but .img instead, try adding it as another drive and booting from there.
# If there is an error "OEM String with app prefix 4E32566D-8E9E-4F52-81D3-5BB9715F9727 not found" try newer OVMF files with keys already enrolled.
secure_boot=0

vm_bridge=vmbridge
net_bridge=netbridge
uefi_bios="/usr/share/edk2-ovmf/OVMF_CODE.fd"
[ "$secure_boot" = 1 ] && uefi_bios="/usr/share/edk2-ovmf/OVMF_CODE.secboot.fd"
# Should be a copy of /usr/share/edk2-ovmf/OVMF_VARS.secboot.fd for storing UEFI variables and keys. Required with secure boot.
uefi_vars="$(basename -s .img $img_name)_OVMF_VARS.secboot.fd"
cdrom_image="image.iso"

# Use "lspci -nn | grep VGA" to check the device id.
# To find out the device bus, list details using device id. E.g. for AMD IGP:
#   $ lspci -nnk -d 1002:13c0
#   11:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Granite Ridge [Radeon Graphics] [1002:13c0] (rev c2)
#   	Subsystem: ASRock Incorporation Device [1849:364e]
#   	Kernel driver in use: vfio-pci
#   	Kernel modules: amdgpu
# See /sys/kernel/iommu_groups/*/devices/* for IOMMU groups, and for details e.g.: lspci -nns 000:11:00
# If two GPUs share the same driver, unbinding the driver ("echo DEVICE-ID > /sys/bus/pci/devices/DEVICE-ID/driver/unbind") would result in X11 crashing.
# If using X11 and auto adding GPUs is disabled, you may want to explicitly define the GPU a device refers to, e.g.
# Section "Device"
#   BusID "PCI:3:0:0" # Here 0000:3:00.0 would be the primary GPU device address.
# Another option is to ignore the passthrough device:
# Section "Device"
#   Driver "modesetting"
#   BusID "PCI:13:0:0"
#   Option "Ignore" "true"
# The driver has probably been loaded already during initramfs, though. In that case create a modprobe rule such as:
#   options vfio-pci ids=1002:13c0
#   softdep amdgpu pre: vfio-pci
# This would make kernel load vfio-pci before amdgpu and bind vfio-pci to id 1002:13c0.
# This script assumes the VGA driver has been bound correctly already. Only the audio driver is unbound.
# NOTE: especially AMD GPUs might have problems with Windows guests not resetting them correctly during guest shut down, resulting in a passed through device working exactly once during host uptime. Take this into account when testing if the passthrough works. A common indication is "error 43" in Windows device manager for the GPU.
# There are tools such as RadeonResetBugFixService.exe to mitigate the problem. What they do is they remove the device from Windows before shutdown, and add the device anew on startup. This forces Windows to reset the device correctly.
passthrough_video_device="0000:11:00.0"
passthrough_audio_device="0000:11:00.1"
passthrough_vbios="vbios_164E.dat"
passthrough_gopdriver="AMDGopDriver.rom"

if [ "$passthrough" = 1 ]
then
    # This will probe: vfio_pci, vfio, vfio_pci_core, vfio_iommu_type1
    # Note that sometimes is required in /etc/modprobe.d/vfio.conf: options vfio_iommu_type1 allow_unsafe_interrupts=1
    modprobe vfio_pci

    if [ -e /sys/bus/pci/devices/$passthrough_audio_device ]
    then
        if [ "$(realpath /sys/bus/pci/devices/$passthrough_audio_device/driver)" != "/sys/bus/pci/drivers/vfio-pci" ]
        then
            [ -e /sys/bus/pci/devices/$passthrough_audio_device/driver/unbind ] && echo $passthrough_audio_device > /sys/bus/pci/devices/$passthrough_audio_device/driver/unbind
            pad_vendor=$(cat /sys/bus/pci/devices/$passthrough_audio_device/vendor)
            pad_device=$(cat /sys/bus/pci/devices/$passthrough_audio_device/device)
            echo "$pad_vendor $pad_device" > /sys/bus/pci/drivers/vfio-pci/new_id
        fi
    fi

    # This root device is required, otherwise guest fails with error 43 for the GPU.
    passthrough_options="-device pcie-root-port,id=pcie0,slot=0"
    [ -e /sys/bus/pci/devices/$passthrough_video_device ] && passthrough_options="$passthrough_options -device vfio-pci,host=$passthrough_video_device,bus=pcie0,addr=00.0,x-vga=on,multifunction=on,romfile=$passthrough_vbios"
    [ -e /sys/bus/pci/devices/$passthrough_audio_device ] && passthrough_options="$passthrough_options -device vfio-pci,host=$passthrough_audio_device,bus=pcie0,addr=00.1,romfile=$passthrough_gopdriver"
fi

modprobe tun
modprobe kvm
lscpu | grep Intel && modprobe kvm-intel || modprobe kvm-amd

if [ "$bridged_network" = 1 ] && [ "$(brctl show $net_bridge 2>&1 | grep "\(No\)\|\(not \)")" ]
then
    echo "Set up the bridged network manually first."
    exit 1
fi

if [ "$(brctl show $vm_bridge 2>&1 | grep "\(No\)\|\(not \)")" ]
then
    if [ "$auto_setup_network" = 0 ]
    then
        echo "The bridge $vm_bridge does not exist. Aborting..."
        exit 1
    fi
fi
./vmnetwork.sh

# Use KVM software, e.g. Input Leap when headless.
# Alternatively use -vga std and Qemu VNC.
# Guest screen might require some input such as a mouse click, even with text-only VNC.
# NOTE: if using passthrough reset fixes such as RadeonResetBugFixService, it might remove the QXL device on startup.
videohw="-vga none"
if [ "$passthrough" = 0 ] || [ ! -e /sys/bus/pci/devices/$passthrough_video_device ]
then
    videohw="-vga std"
    if [ ! "$(echo quit | qemu-system-x86_64 -vga qxl -machine none -nographic 2>&1 | grep QXL)" ]
    then
        port=$net_id
        [ "$net_id" -lt 10 ] && port="0"$port
        videohw="-device qxl-vga,vgamem_mb=64,ram_size_mb=256,vram_size_mb=256 \
            -device virtio-serial-pci \
            -device virtserialport,chardev=spicechannel$net_id,name=com.redhat.spice.0 \
            -chardev spicevmc,id=spicechannel$net_id,name=vdagent \
            -spice port=600$port,addr=127.0.0.1,disable-ticketing=on"
    fi
fi

soundhw=""
if [ "$audio" = 1 ]
then
    soundhw="-device intel-hda -device hda-duplex,audiodev=snd$net_id"
    if [ "$(ps -e | grep pulseaudio)" ]
    then
        socket=$(ls /run/user/*/pulse/native 2>/dev/null | head -n 1)
        [ ! "$socket" ] && continue
        user=$(ls -o $socket | cut -f 3 -d ' ')
        cp /home/$user/.config/pulse/cookie ~/.config/pulse/cookie
        soundhw="$soundhw -audiodev pa,id=snd$net_id,server=unix:$socket"
    else
        modprobe snd-aloop
        dac="hw:Loopback,,0,,4" # loop_vm_dac_in
        adc="hw:Loopback,,1,,5" # loop_vm_adc_out
        soundhw="$soundhw -audiodev alsa,id=snd$net_id,out.dev=$dac,in.dev=$adc"
    fi
fi

boot_options="order=c"
[ "$boot_from_cd" = 1 ] && boot_options="order=d -cdrom $cdrom_image"
[ "$boot_menu" = 1 ] && boot_options="menu=on"

# Note: if you have multiple virtual machines, their network devices must have different MAC addresses. Otherwise only one works at a time.
mac_end=$net_id
[ "$net_id" -lt 10 ] && mac_end="0"$mac_end

bridged_net_devices=""
[ "$bridged_network" = 1 ] && bridged_net_devices=\
    "-device virtio-net-pci,netdev=brdev$net_id,mac=00:00:00:00:01:$mac_end -netdev tap,id=brdev$net_id,br=$net_bridge,script=kvm_tap_netbridge.sh"

uefi_options=""
[ "$uefi" = 1 ] && uefi_options="-smbios type=0,uefi=on -bios $uefi_bios"

tpm_options=""
if [ "$tpm" = 1 ]
then
    mkdir -p /tmp/emulated_tpm
    [ ! "$(ps -ef | grep "swtpm.*/tmp/emulated_tpm.*level=20$")" ] && \
    swtpm socket -d --tpm2 --tpmstate dir=/tmp/emulated_tpm \
    --ctrl type=unixio,path=/tmp/emulated_tpm/swtpm-sock \
    --log level=20
    tpm_options="-chardev socket,id=chrtpm,path=/tmp/emulated_tpm/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
fi

secure_boot_options=""
if [ "$secure_boot" = 1 ]
then
    [ ! -e "$uefi_vars" ] && echo "$uefi_vars doesn't exist." && exit 1
    secure_boot_options="-global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file=$uefi_bios,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=$uefi_vars \
    -global ICH9-LPC.disable_s3=1"
    # Need to disable ACPI S3 suspend/resume, otherwise will result in error:
    # "Guest has not initialized the display (yet)."
    # https://bugs.archlinux.org/task/59465.html
fi

# Shall the guest know it is running virtualized. Turning off might help when installing certain drivers (e.g. for passthrough GPU).
cpu_host_kvm=off

echo "Starting the virtual machine..."
qemu-system-x86_64 \
-daemonize \
-enable-kvm \
-name "$vm_name" \
-boot $boot_options \
-machine q35,accel=kvm \
-cpu host,kvm=$cpu_host_kvm,+topoext \
-smp cores=$vm_num_cores,threads=$vm_threads_per_core,sockets=1 \
-m $vm_mem_mb \
-k fi \
-display vnc=localhost:$net_id \
-device virtio-net,netdev=netdev$net_id,mac=00:00:00:00:00:$mac_end -netdev tap,id=netdev$net_id,br=$vm_bridge,script=kvm_tap_vmbridge.sh \
-drive file="$img_name",if=virtio,format=raw \
$bridged_net_devices \
$soundhw \
$videohw \
$uefi_options \
$tpm_options \
$secure_boot_options

# Common workarounds and tweaks:
# * Fixes most problems and some BSODs in Windows, especially during setup:
#     -cpu core2duo \
# * Required if VM hangs during POST until VNC connection is established:
#     -no-kvm-irqchip \
# * The br parameter for netdev does not work, it always adds the tap device to first bridge found. Therefore we need to use scripts.
# * To fix cursor position in Windows clients, use the usb-tablet device. It might help in VNC connections with other guests also:
#     -device usb-tablet \
# * Pass a single USB port through to client (check bus and port with lsusb -t):
#     -device usb-host,hostbus=1,hostport=1 \
#   * After Qemu version ~2.10.50, passed devices need to have a manually defined USB host controller. However, there is no need to define the "id", "bus" or "addr" parameters anymore. The USB device speed must also match the host controller speed: for example, a USB headset probably requires nec-usb-xhci.
#   * In short: first define the controller, then the device which should attach to it.
#   * The deprecated -usbdevice option implied the ich9-usb-uhci[123] and ich-9-usb-echi1 controllers.
#   * Therefore, to use usb-tablet and pass through devices (note the USB device definitions before $passthrough_options, otherwise e.g. mouse might not work), add:
#       -device ich9-usb-uhci1 \
#       -device ich9-usb-uhci2 \
#       -device ich9-usb-uhci3 \
#       -device ich9-usb-ehci1 \
#       -device usb-tablet \
#       -device nec-usb-xhci \
#       -device usb-host,hostbus=1,hostport=1 \
#       $passthrough_options

sleep 2

# The PID changes so we cannot use last PID.
pid=$(ps -ef | grep "qemu.*$vm_name" | grep -v grep | tr -s ' ' | cut -f 2 -d ' ')
if [ "$pid" ]
then
    renice +15 $pid
fi

if [ "$(which gvncviewer 2>/dev/null)" ]
then
    vncviewer="gvncviewer localhost:$net_id"
elif [ "$(which vncviewer 2>/dev/null)" ]
then
    vncviewer="vncviewer :$net_id"
fi
[ "$auto_start_vnc" = 1 ] && [ "$vncviewer" ] && $vncviewer &
