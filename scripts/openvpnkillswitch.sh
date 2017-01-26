#!/bin/bash
# Establish an OpenVPN connection using $1 as config.
# Creates an iptables filter working as a VPN kill switch.
# VPN server IP is deduced after succesful connection.

# For now we need to know beforehand how many IP routes the VPN
# connection is expected to create when initializing.
routes_to_create=5

if [ "$#" == 0 ]
then
    echo "You must give the OpenVPN config file as parameter."
    exit
fi

if test "X$(which openvpn)" == "X"
then
    echo "OpenVPN executable not found."
    exit
fi

for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
do
    ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
    if test "X$ip" != "X"
    then
        IF=$physical_device
        break
    fi
done

echo "Using interface $IF and config file $1"

current_routes=$(ip route show | grep $IF | cut -f 1 -d ' ')
num_routes=$(expr $(ip route show | wc -l) + $routes_to_create)

echo -n "Connecting VPN..."
openvpn $1 &>/dev/null &

# Wait till VPN routes are set up.
while [ $(ip route show | wc -l) -ne $num_routes ]
do
    sleep 0.5
    echo -n "."
done
echo -e "\nVPN connection is active."

new_routes=$(ip route show | grep $IF | cut -f 1 -d ' ')
vpn_ip=""
for route in $new_routes
do
    vpn_ip=$route
    for counterpart in $current_routes
    do
        if test "$route" == "$counterpart"
        then
            vpn_ip=""
        fi
    done
    if test "X$vpn_ip" != "X"
    then
        break
    fi
done
if test "X$vpn_ip" == "X"
then
    echo "ERROR: VPN IP not found from routes."
    exit
fi

iptables -F
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A OUTPUT -o tun+ -j ACCEPT
iptables -A INPUT -p udp --sport 1194 -s $vpn_ip -j ACCEPT
iptables -A OUTPUT -p udp --dport 1194 -d $vpn_ip -j ACCEPT
echo "Created iptables rules. Firewall is now enabled."

function killvpn() {
    echo -e "\nKilling VPN connection..."
}

while [ 1 ]
do
    trap killvpn 2
    wait
    echo "VPN connection lost. Reconnecting in 5 seconds..."
    echo "To cancel, press c."
    read -s -N 1 -t 5 cancel
    trap 2

    if test "X$cancel" == "Xc"
    then
        break
    fi

    echo "DNS traffic allowed outside VPN."
    iptables -A INPUT -p udp --sport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

    num_routes=$(expr $(ip route show | wc -l) + $routes_to_create)
    echo -n "Reconnecting VPN..."
    openvpn $1 &>/dev/null &
    while [ $(ip route show | wc -l) -ne $num_routes ]
    do
        sleep 0.5
        echo -n "."
    done
    echo -e "\nVPN connection is active."

    iptables -D INPUT -p udp --sport 53 -j ACCEPT
    iptables -D OUTPUT -p udp --dport 53 -j ACCEPT
    echo "DNS traffic disabled outside VPN."
done

iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
echo "Flushed iptables rules. Firewall is now disabled."
sleep 1
