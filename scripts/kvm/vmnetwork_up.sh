#!/bin/bash
# Source the network_down script to undo everything.
echo -e "" > network_down

adapter=$1
if test "X$adapter" == "X"
then
    echo "Remember to give adapter parameter when on Wi-Fi!"
    adapter=eth0
fi

modprobe tun

ip=$(ifconfig | grep -A 1 $adapter | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")

jump="MASQUERADE"
if test "X$ip" != "X"
then
    jump="SNAT --to-source $ip"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump
echo "sudo sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=0" >> network_down
echo "sudo iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump" >> network_down

# Virtual machine bridge.
brctl addbr vmbridge
ip link set vmbridge up
ip addr add 10.0.1.1/24 dev vmbridge scope host
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
if test "X$(ip link | grep tap0)" != "X"
then
    brctl addif vmbridge tap0
fi

echo "sudo sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0" >> network_down
echo "sudo ip addr del 10.0.1.1/24 dev vmbridge scope host" >> network_down
echo "sudo ip link set vmbridge down" >> network_down
echo "sudo brctl delbr vmbridge" >> network_down

# Virtual localhost. Use this IP within guests to use services running locally on the host.
ip tuntap add mode tap vlocalhost
ip link set vlocalhost up
ip addr add 10.0.1.127/24 dev vlocalhost scope host
iptables -t nat -A PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1

echo "sudo iptables -t nat -D PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1" >> network_down
echo "sudo ip addr del 10.0.1.127/24 dev vlocalhost scope host" >> network_down
echo "sudo ip link set vlocalhost down" >> network_down
echo "sudo ip tuntap del mode tap vlocalhost" >> network_down
