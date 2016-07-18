#!/bin/bash
# Source the network_down script to undo everything.
echo -e "" > network_down

modprobe tun

# Note that not every network interface supports bridging.
adapter="eth0"
ifconfig $adapter 0.0.0.0

brctl addbr vmbridge
ip link set vmbridge up
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
brctl addif vmbridge $adapter
if test "X$(ip link | grep tap0)" != "X"
then
    ifconfig tap0 0.0.0.0
    brctl addif vmbridge tap0
fi
dhclient vmbridge

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
