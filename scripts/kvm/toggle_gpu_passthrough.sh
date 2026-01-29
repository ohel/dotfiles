#!/usr/bin/sh
# Toggles a GPU device $1 between X driver $2 and VFIO-PCI driver. Optional audio device $3 is toggled for VFIO-PCI also.
# Some notes about stability:
# * Toggling from $driver to VFIO-PCI probably crashes X, and might not succeed to bind, hanging up the echo command to bind.
# * Toggling from VFIO-PCI to $driver might not always work, or not work but once. Kernel bugs, NULL dereferences etc. may occur.
# * Even a direct kernel command line option like vfio_pci.ids=1002:13c0 might not prevent amdgpu from binding to device 1002:13c0 instead of vfio-pci.

gpu_dev=${1:-"0000:11:00.0"}
driver=${2:-"amdgpu"}
audio_dev=${3:-"0000:11:00.1"}

# Is VFIO currently in use?
is_vfio="" && [ "$(realpath /sys/bus/pci/devices/$gpu_dev/driver)" = "/sys/bus/pci/drivers/vfio-pci" ] && is_vfio=yes
[ ! "$is_vfio" ] && modprobe vfio_pci # Will probe: vfio, vfio_pci, vfio_pci_core, vfio_iommu_type1

wd=$(pwd)

if [ "$audio_dev" ] && [ -e /sys/bus/pci/devices/$audio_dev ]
then
    dev_vendor=$(cat /sys/bus/pci/devices/$audio_dev/vendor)
    dev_device=$(cat /sys/bus/pci/devices/$audio_dev/device)
    echo "Audio: $dev_vendor $dev_device"

    if [ "$is_vfio" ] && [ "$(realpath /sys/bus/pci/devices/$audio_dev/driver 2>/dev/null)" = "/sys/bus/pci/drivers/vfio-pci" ]
    then
        # The new driver will most probably be snd_hda_intel.
        echo "Switching audio device $audio_dev out of VFIO-PCI. Driver will be bound along with GPU."
        echo $audio_dev > /sys/bus/pci/drivers/vfio-pci/unbind
        echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null
    elif [ ! "$is_vfio" ]
    then
        echo "Switching audio device $audio_dev to VFIO-PCI."
        if [ -e /sys/bus/pci/devices/$audio_dev/driver ] && [ "$(realpath /sys/bus/pci/devices/$audio_dev/driver)" != "/sys/bus/pci/drivers/vfio-pci" ]
        then
            cd -P /sys/bus/pci/devices/$audio_dev/driver
            [ -e unbind ] && echo $audio_dev > unbind
            [ -e remove_id ] && echo "$dev_vendor $dev_device" > remove_id 2>/dev/null
        fi

        # Some drivers use bind, while others use new_id. Try both.
        echo $audio_dev > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null
        echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null
    fi
fi

dev_vendor=$(cat /sys/bus/pci/devices/$gpu_dev/vendor)
dev_device=$(cat /sys/bus/pci/devices/$gpu_dev/device)
echo "GPU: $dev_vendor $dev_device"

if [ "$is_vfio" ] && [ "$(realpath /sys/bus/pci/devices/$gpu_dev/driver 2>/dev/null)" = "/sys/bus/pci/drivers/vfio-pci" ]
then
    echo "Switching GPU device $gpu_dev out of VFIO-PCI. Binding to $driver."
    echo $gpu_dev > /sys/bus/pci/drivers/vfio-pci/unbind
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null

    # Some drivers use bind, while others use new_id. Try both.
    echo $gpu_dev > /sys/bus/pci/drivers/$driver/bind 2>/dev/null
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/$driver/new_id 2>/dev/null
elif [ ! "$is_vfio" ]
then
    echo "Switching GPU device $gpu_dev to VFIO-PCI."
    if [ -e /sys/bus/pci/devices/$gpu_dev/driver ] && [ "$(realpath /sys/bus/pci/devices/$gpu_dev/driver)" != "/sys/bus/pci/drivers/vfio-pci" ]
    then
        cd -P /sys/bus/pci/devices/$gpu_dev/driver
        [ -e unbind ] && echo $gpu_dev > unbind
        [ -e remove_id ] && echo "$dev_vendor $dev_device" > remove_id 2>/dev/null
    fi

    # Some drivers use bind, while others use new_id. Try both.
    echo $gpu_dev > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null
fi

cd $wd
