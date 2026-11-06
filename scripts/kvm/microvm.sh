#!/usr/bin/sh

if [ "$1" = "create" ]
then
  alpine_img=alpine-virt-3.24.4-x86_64.iso
  [ ! -e $alpine_img ] && echo "Missing Alpine Linux image." && exit 1

  qemu-img create -f raw rootfs.img 2G

  echo "Login as: root (no password)"
  echo "Then run: setup-alpine"
  echo "User-mode NAT and a virtualized ethernet controller are available inside the VM."
  echo "Select vda as the disk to use, and sys as the way to use it. Erase the disk and continue."

  exec qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -m 2G \
    -cdrom $alpine_img \
    -drive file=rootfs.img,if=virtio,format=raw
fi

tap_dev=tap-microvm
if ! ip tuntap 2>/dev/null | cut -f 1 -d ':' | grep $tap_dev\$ >/dev/null
then
  sudo ./vmnetwork.sh "tap=$tap_dev"
fi

fs_socket=/tmp/microvmfs.sock
if ! ps -ef | grep "$fs_socket" | grep -v grep >/dev/null
then
  /usr/libexec/virtiofsd --socket-path=$fs_socket --shared-dir=/mnt/exports/sandbox &
  chmod a+rw $fs_socket
fi

echo "Shut down with: poweroff"

# Note that microvm doesn't have PCI bus so virtio devices need to be MMIO versions defined by the -device postfix.
# Copy kernel and initrd from Alpine Linux install image.
# Using virtiofsd needs the memory to be shared.
fs_socket=/tmp/microvmfs.sock
exec qemu-system-x86_64 \
  -enable-kvm \
  -object memory-backend-memfd,id=mem_be,share=on,size=2G \
  -machine microvm,memory-backend=mem_be \
  -cpu host \
  -kernel vmlinuz-virt \
  -initrd initramfs-virt \
  -append "console=ttyS0 root=/dev/vda3 rootfstype=ext4 rw" \
  -device virtio-blk-device,drive=rootdrive \
  -drive id=rootdrive,file=microvm.img,format=raw \
  -device virtio-net-device,netdev=ethdev,mac=00:00:00:00:00:cc \
  -netdev tap,id=ethdev,ifname=$tap_dev,script=no,downscript=no \
  -chardev socket,id=vfs,path=$fs_socket \
  -device vhost-user-fs-device,chardev=vfs,tag=hostshare \
  -nographic

