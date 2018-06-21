#!/bin/bash
# Set up networking for KVM virtual machines:
# - SNAT to first PCI NIC, or $1 if given.
# - Optionally ($2 == "bridge") set up network bridge where bridged VM tap devices should be added.
# - Set up virtual machine bridge where routed VM tap devices should be added.
# - Set up virtual localhost for consistent host access.
# Source $reset_script to undo everything.

reset_script=network_reset

echo -e "" > $reset_script

modprobe tun

if [ "$#" == 0 ]
then
    for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
    do
        ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
        if test "X$ip" != "X"
        then
            nic=$physical_device
            break
        fi
    done
else
    nic=$1
    if test "X$(ls -l /sys/class/net | grep devices\/pci | cut -f 11 -d ' ' | grep -o $nic)" != "X$nic"
    then
        echo "Network device not found: $nic"
        exit
    fi
    ip=$(ip addr show $nic| grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
fi

echo "Using adapter: $nic with IP: $ip"

forward=$(sysctl -q -e net.ipv4.conf.$nic.forwarding | cut -f 3 -d ' ')
sysctl -q -e -w net.ipv4.conf.$nic.forwarding=1
echo "sudo sysctl -q -e -w net.ipv4.conf.$nic.forwarding=$forward" >> $reset_script

# Network bridge. Note: not all interfaces support bridging.
if [ "X$2" == "Xbridge" ]
then
  if brctl show | cut -f 1 | grep netbridge\$ >/dev/null
  then
      echo "Network bridge already exists."
  else
      brctl addbr netbridge
      ip link set netbridge up
      sysctl -q -e -w net.ipv4.conf.netbridge.forwarding=1
      ifconfig $nic 0.0.0.0
      brctl addif netbridge $nic
      dhclient netbridge

      echo "sudo sysctl -q -e -w net.ipv4.conf.netbridge.forwarding=0" >> $reset_script
      echo "sudo ip link set netbridge down" >> $reset_script
      echo "sudo brctl delbr netbridge" >> $reset_script
      echo "sudo ifconfig $nic $ip" >> $reset_script

      ip=$(ip addr show netbridge | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
      echo "Using netbridge with IP: $ip"
  fi
fi

# Virtual machine bridge.
if brctl show | cut -f 1 | grep vmbridge\$ >/dev/null
then
    echo "Virtual machine bridge already exists."
else
    brctl addbr vmbridge
    ip link set vmbridge up
    ip addr add 10.0.1.1/24 dev vmbridge scope host
    ip addr add fe80::1:1/64 dev vmbridge scope site
    sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
    sysctl -q -e -w net.ipv6.conf.vmbridge.forwarding=1

    echo "sudo sysctl -q -e -w net.ipv6.conf.vmbridge.forwarding=0" >> $reset_script
    echo "sudo sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0" >> $reset_script
    echo "sudo ip addr del fe80::1:1/64 dev vmbridge scope site" >> $reset_script
    echo "sudo ip addr del 10.0.1.1/24 dev vmbridge scope host" >> $reset_script
    echo "sudo ip link set vmbridge down" >> $reset_script
    echo "sudo brctl delbr vmbridge" >> $reset_script
fi

# Virtual machine bridge NAT.
rule="POSTROUTING -s 10.0.1.0/24 -o $nic -j SNAT --to-source $ip"
if iptables -t nat -C $rule 2>/dev/null
then
    echo "Virtual machine bridge NAT routing rule already exists."
else
    iptables -t nat -A $rule
    echo "sudo iptables -t nat -D $rule" >> $reset_script
fi

# Virtual localhost. Use this IP within guests to use services running locally on the host.
if ip tuntap 2>/dev/null | cut -f 1 -d ':' | grep vlocalhost\$ >/dev/null
then
    echo "Virtual localhost already exists."
else
    ip tuntap add mode tap vlocalhost
    ip link set vlocalhost up
    ip addr add 10.0.1.127/24 dev vlocalhost scope host
    rule="PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1"
    iptables -t nat -A $rule

    echo "sudo iptables -t nat -D $rule" >> $reset_script
    echo "sudo ip addr del 10.0.1.127/24 dev vlocalhost scope host" >> $reset_script
    echo "sudo ip link set vlocalhost down" >> $reset_script
    echo "sudo ip tuntap del mode tap vlocalhost" >> $reset_script
fi
