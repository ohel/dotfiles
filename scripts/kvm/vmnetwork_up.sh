#!/bin/bash
# Set up networking for KVM virtual machines:
# - SNAT to first PCI NIC, or $1 if given.
# - Set up virtual machine bridge where VM tap devices should be added.
# - Set up virtual localhost for consistent host access.
# Source the network_down script to undo everything.
echo -e "" > network_down

if [ "$#" == 0 ]
then
    for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
    do
        ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
        if test "X$ip" != "X"
        then
            adapter=$physical_device
            break
        fi
    done
else
    adapter=$1
    ip=$(ip addr show $adapter | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
fi

echo "Using adapter: $adapter with IP: $ip"

modprobe tun

jump="MASQUERADE"
if test "X$ip" != "X"
then
    jump="SNAT --to-source $ip"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=1
echo "sudo sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=0" >> network_down

if iptables -t nat -C POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump 2>/dev/null
then
    echo "Routing rule already exists."
else
    iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump
    echo "sudo iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump" >> network_down
fi

# Virtual machine bridge.
if brctl show | cut -f 1 | grep vmbridge\$ >/dev/null
then
    echo "Virtual machine bridge already exists."
else
    brctl addbr vmbridge
    ip link set vmbridge up
    ip addr add 10.0.1.1/24 dev vmbridge scope host
    sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1

    echo "sudo sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0" >> network_down
    echo "sudo ip addr del 10.0.1.1/24 dev vmbridge scope host" >> network_down
    echo "sudo ip link set vmbridge down" >> network_down
    echo "sudo brctl delbr vmbridge" >> network_down
fi

# Virtual localhost. Use this IP within guests to use services running locally on the host.
if ip tuntap | cut -f 1 -d ':' | grep vlocalhost\$ >/dev/null
then
    echo "Virtual localhost already exists."
else
    ip tuntap add mode tap vlocalhost
    ip link set vlocalhost up
    ip addr add 10.0.1.127/24 dev vlocalhost scope host
    iptables -t nat -A PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1

    echo "sudo iptables -t nat -D PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1" >> network_down
    echo "sudo ip addr del 10.0.1.127/24 dev vlocalhost scope host" >> network_down
    echo "sudo ip link set vlocalhost down" >> network_down
    echo "sudo ip tuntap del mode tap vlocalhost" >> network_down
fi
