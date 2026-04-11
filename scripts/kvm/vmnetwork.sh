#!/usr/bin/sh
# Set up networking for KVM virtual machines:
# - SNAT to first PCI NIC, or $1 if given. $1 may be also a filename, with file contents being the NIC.
# - Optionally ($2 = "bridge" or "b") set up network bridge where bridged VM tap devices should be added.
# - Set up virtual machine bridge where routed VM tap devices should be added.
# - Set up virtual localhost for consistent host access.
# - Specify chains to nftables.
# Source $reset_script to undo everything.

reset_script=network_reset
echo "" > $reset_script

modprobe tun

nic=$(ip route show default | awk '{print $5}')
if [ "$#" != 0 ]
then
    nic="$1"
    [ -f "$1" ] && nic=$(cat "$1")

    if [ "$(ls -l /sys/class/net | grep devices/pci | grep -o '-> [^ ]*' | grep -o $nic)" != "$nic" ]
    then
        echo "Network device not found: $nic"
        exit 1
    fi
fi
ip=$(ip -4 addr show "$nic" | awk '/inet / {print $2}' | cut -d '/' -f 1)

echo "Using adapter: $nic with IP: $ip"
echo "Setting up forward policies..."

forward=$(sysctl -q -e net.ipv4.conf.$nic.forwarding | cut -f 3 -d ' ')
sysctl -q -e -w net.ipv4.conf.$nic.forwarding=1
echo "sudo sysctl -q -e -w net.ipv4.conf.$nic.forwarding=$forward" >> $reset_script

# Packet forwarding so that access to other networks such as Internet works.
if ! nft list chain inet filter vm_forward 2>/dev/null | grep -q "policy accept"
then
    nft list table inet filter >/dev/null 2>&1 || nft add table inet filter
    nft list chain inet filter vm_forward >/dev/null 2>&1 || nft add chain inet filter vm_forward '{ type filter hook forward priority 0; policy accept; }'
    echo "sudo nft delete chain inet filter vm_forward 2>/dev/null" >> $reset_script
else
    echo "Packet forwarding chains already defined."
fi

# Network bridge using DHCP. Note: not all interfaces support bridging.
if [ "$2" = "bridge" ] || [ "$2" = "b" ]
then
    if [ "$(ip link show type bridge | grep ": netbridge:")" ]
    then
        echo "Network bridge already exists."
    else
        echo "Setting up network bridge..."

        ip link add name netbridge type bridge
        ip link set netbridge up
        ip addr flush dev $nic
        ip link set $nic master netbridge
        dhcpcd -n -w -4 --nohook resolv.conf netbridge
        sysctl -q -e -w net.ipv4.conf.netbridge.forwarding=1

        echo "sudo ip link set netbridge down" >> $reset_script
        echo "sudo ip link delete netbridge type bridge" >> $reset_script
        echo "sudo ip addr add $ip/24 dev $nic" >> $reset_script

        ip=$(ip address show netbridge | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
        echo "Using netbridge with IP: $ip"
    fi
fi

# Virtual machine bridge.
if [ "$(ip link show type bridge | grep ": vmbridge:")" ]
then
    echo "Virtual machine bridge already exists."
else
    echo "Setting up virtual machine bridge..."

    ip link add name vmbridge type bridge
    ip link set vmbridge up
    ip address add 10.0.1.1/24 dev vmbridge
    [ "$(sysctl -n net.ipv6.conf.vmbridge.disable_ipv6 2>/dev/null)" != "1" ] && \
        ip address add fe80::1:1/64 dev vmbridge
    sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
    sysctl -q -e -w net.ipv6.conf.vmbridge.forwarding=1

    echo "sudo ip link set vmbridge down" >> $reset_script
    echo "sudo ip link delete vmbridge type bridge" >> $reset_script
fi

# Virtual machine bridge NAT.
nft list table ip vm_nat >/dev/null 2>&1 || nft add table ip vm_nat
nft list chain ip vm_nat postrouting >/dev/null 2>&1 || nft add chain ip vm_nat postrouting '{ type nat hook postrouting priority 100; }'
rule_expr="ip saddr 10.0.1.0/24 oif \"$nic\" snat to $ip"
if nft list chain ip vm_nat postrouting | grep -q "$rule_expr"
then
    echo "Virtual machine bridge NAT routing rule already exists."
else
    nft add rule ip vm_nat postrouting $rule_expr
    handle=$(nft -a list chain ip vm_nat postrouting | \
        grep "$rule_expr" | \
        sed -n 's/.*handle \([0-9]\+\)$/\1/p')
    echo "sudo nft delete rule ip vm_nat postrouting handle $handle" >> $reset_script
fi

# Virtual localhost. Use this IP within guests to use services running locally on the host.
vm_guest_host_ip="10.0.1.127/24"
if ip tuntap 2>/dev/null | cut -f 1 -d ':' | grep vlocalhost\$ >/dev/null
then
    echo "Virtual localhost already exists."
else
    echo "Setting up virtual localhost..."

    ip tuntap add mode tap vlocalhost
    ip link set vlocalhost up
    ip address add $vm_guest_host_ip dev vlocalhost

    nft add chain ip vm_nat prerouting '{ type nat hook prerouting priority -100; }'
    rule_expr="iif \"vlocalhost\" dnat to 127.0.0.1"
    nft add rule ip vm_nat prerouting $rule_expr
    handle=$(nft -a list chain ip vm_nat prerouting | \
        grep "vlocalhost" | \
        sed -n 's/.*handle \([0-9]\+\).*/\1/p')

    echo "sudo nft delete rule ip vm_nat prerouting handle $handle" >> $reset_script
    echo "sudo ip link set vlocalhost down" >> $reset_script
    echo "sudo ip tuntap del mode tap vlocalhost" >> $reset_script
fi
