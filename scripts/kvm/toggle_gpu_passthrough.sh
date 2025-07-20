#!/usr/bin/sh
# Toggles a GPU device $1 between X driver $2 and VFIO-PCI driver. Optional audio device $3 is toggled for VFIO-PCI also.
# Note that toggling from $driver to VFIO-PCI probably crashes X.
# Also toggling from VFIO-PCI to $driver might not always work, or work more than once. Kernel bugs, NULL dereferences etc. may occur.

gpu=${1:-"0000:11:00.0"}
driver=${2:-"amdgpu"}
audio=${3:-"0000:11:00.1"}

# Is VFIO currently in use?
is_vfio="" && [ "$(realpath /sys/bus/pci/devices/$gpu/driver)" = "/sys/bus/pci/drivers/vfio-pci" ] && is_vfio=yes
[ ! "$is_vfio" ] && modprobe vfio_pci # Will probe: vfio, vfio_pci, vfio_pci_core, vfio_iommu_type1

wd=$(pwd)

if [ "$audio" ] && [ -e /sys/bus/pci/devices/$audio ]
then
    dev_vendor=$(cat /sys/bus/pci/devices/$audio/vendor)
    dev_device=$(cat /sys/bus/pci/devices/$audio/device)
    echo "Audio: $dev_vendor $dev_device"

    if [ "$is_vfio" ] && [ "$(realpath /sys/bus/pci/devices/$audio/driver 2>/dev/null)" = "/sys/bus/pci/drivers/vfio-pci" ]
    then
        echo "Switching audio device $audio out of VFIO-PCI. Driver will be bound along with GPU."
        echo $audio > /sys/bus/pci/drivers/vfio-pci/unbind
        echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null
    elif [ ! "$is_vfio" ]
    then
        echo "Switching audio device $audio to VFIO-PCI."
        if [ -e /sys/bus/pci/devices/$audio/driver ] && [ "$(realpath /sys/bus/pci/devices/$audio/driver)" != "/sys/bus/pci/drivers/vfio-pci" ]
        then
            cd -P /sys/bus/pci/devices/$audio/driver
            [ -e unbind ] && echo $audio > unbind
            [ -e remove_id ] && echo "$dev_vendor $dev_device" > remove_id 2>/dev/null
        fi
        echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/new_id
    fi
fi

dev_vendor=$(cat /sys/bus/pci/devices/$gpu/vendor)
dev_device=$(cat /sys/bus/pci/devices/$gpu/device)
echo "GPU: $dev_vendor $dev_device"

if [ "$is_vfio" ] && [ "$(realpath /sys/bus/pci/devices/$gpu/driver 2>/dev/null)" = "/sys/bus/pci/drivers/vfio-pci" ]
then
    echo "Switching GPU device $gpu out of VFIO-PCI. Binding to $driver."
    echo $gpu > /sys/bus/pci/drivers/vfio-pci/unbind
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null
    echo $gpu > /sys/bus/pci/drivers/$driver/bind 2>/dev/null # Some drivers use bind...
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/$driver/new_id 2>/dev/null # ...while others use new_id.
elif [ ! "$is_vfio" ]
then
    echo "Switching GPU device $gpu to VFIO-PCI."
    if [ -e /sys/bus/pci/devices/$gpu/driver ] && [ "$(realpath /sys/bus/pci/devices/$gpu/driver)" != "/sys/bus/pci/drivers/vfio-pci" ]
    then
        cd -P /sys/bus/pci/devices/$gpu/driver
        [ -e unbind ] && echo $gpu > unbind
        [ -e remove_id ] && echo "$dev_vendor $dev_device" > remove_id 2>/dev/null
    fi
    echo "$dev_vendor $dev_device" > /sys/bus/pci/drivers/vfio-pci/new_id
fi

cd $wd
