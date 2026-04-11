#!/usr/bin/sh
# Prevent all network connections except LAN and VM bridge. Disable forwarding.

if ! command -v nft >/dev/null; then
    echo "Command nft not found. Do you have (root) access?"
    exit 1
fi

nic=$(ip route show default | awk '{print $5}')
ip=$(ip -4 addr show "$nic" | awk '/inet / {print $2}' | cut -d '/' -f 1)

if [ "$1" = "restore" ]
then
    nft flush ruleset

    sysctl -q -e -w net.ipv4.conf.$nic.forwarding=1
    sysctl -q -e -w net.ipv6.conf.$nic.forwarding=1

    echo "Flushed nft rules. WAN connections are allowed."
    sleep 1
    exit 0
fi

case "$ip" in
    10.*|192.168.*)
        ;;
    *)
        echo "Unsupported LAN IP: $ip"
        exit 1
        ;;
esac

nft add table inet firewall 2>/dev/null
nft add chain inet firewall input  '{ type filter hook input priority 0; policy drop; }' 2>/dev/null
nft add chain inet firewall output '{ type filter hook output priority 0; policy drop; }' 2>/dev/null

# Allow loopback.
nft add rule inet firewall input iif lo accept
nft add rule inet firewall output oif lo accept

lan_prefix=$(ip -4 route show dev "$nic" scope link | awk '{print $1}' | head -n 1)

# Allow LAN traffic.
nft add rule inet firewall input ip saddr $lan_prefix ip daddr $ip accept
nft add rule inet firewall output ip saddr $ip ip daddr $lan_prefix accept

# If there's a virtual machine bridge, allow that too.
vmbridge_net=$(ip addr show vmbridge 2>/dev/null | grep "inet " | tr -s ' ' | cut -f 3 -d ' ' | cut -f 1 -d '/' | cut -f 1-3 -d '.')

if [ "$vmbridge_net" ]; then
    vm_net="$vmbridge_net.0/24"

    nft add rule inet firewall input ip saddr $vm_net ip daddr $vm_net accept
    nft add rule inet firewall input ip saddr $vm_net ip daddr $lan_prefix accept

    nft add rule inet firewall output ip saddr $vm_net ip daddr $vm_net accept
    nft add rule inet firewall output ip saddr $lan_prefix ip daddr $vm_net accept
fi

sysctl -q -e -w net.ipv4.conf.$nic.forwarding=0
sysctl -q -e -w net.ipv6.conf.$nic.forwarding=0

echo "WAN connections are prevented."
sleep 1
