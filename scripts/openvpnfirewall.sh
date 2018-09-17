#!/bin/bash
# Establish an OpenVPN connection using $1 as config and
# create an iptables filter working like a VPN kill switch.
# VPN server IP is deduced after succesful connection, so it may be dynamic.
# If "allowlan" is given as $2, LAN traffic is allowed, otherwise it is not.
# NB: the script will flush the iptables filter chain.
# IPv4 is assumed for VPN operation. IPv6 traffic is blocked with ip6tables.

logfile=~/.cache/openvpn.log

if [ "$#" == 0 ]
then
    echo "You must give the OpenVPN config file as parameter."
    exit 1
fi

if test "X$(which openvpn)" = "X"
then
    echo "OpenVPN executable not found."
    exit 1
fi

for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
do
    ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
    if test "X$ip" != "X"
    then
        IF=$physical_device
        if test "X$2" = "Xallowlan"
        then
            subnet=$(echo $ip | cut -f 1 -d '.')
        fi
        break
    fi
done

echo "Using interface $IF and config file $1"
echo "OpenVPN output is logged into $logfile"
echo "To kill the connection, press Ctrl-c and then c."

routes=$(ip route show | grep $IF | cut -f 1 -d ' ')
num_routes=$(ip route show | wc -l)

modprobe tun

echo -n "Connecting VPN..."
openvpn $1 &>$logfile &

# Wait till no more routes seem to be created for the VPN connection. The number of routes depends on the VPN and system configuration.
wait_routes() {
    num_routes=$1
    first_route=${2:-1}
    wait_cycle_count=0
    while [[ $wait_cycle_count -lt 10 || $first_route -ne 0 ]]
    do
        echo -n "."
        sleep 0.25 || sleep 1
        if [ $(ip route show | wc -l) -ne $num_routes ]
        then
            first_route=0
            wait_cycle_count=0
            num_routes=$(ip route show | wc -l)
        else
            wait_cycle_count=$(expr $wait_cycle_count + 1)
        fi
        if [[ $wait_cycle_count -gt 40 && $first_route -ne -1 ]]
        then
            killall openvpn &>/dev/null
            echo
            echo "Failed to connect. Log file is printed below."
            echo; cat $logfile; echo
            echo "Press return to exit."
            read
            exit 1
        fi
    done
}
wait_routes $num_routes
echo -e "\n\nVPN connection is active."

new_routes=$(ip route show | grep $IF | cut -f 1 -d ' ')
vpn_ip=""
for route in $new_routes
do
    vpn_ip=$route
    for counterpart in $routes
    do
        if test "$route" = "$counterpart"
        then
            vpn_ip=""
        fi
    done
    if test "X$vpn_ip" != "X"
    then
        break
    fi
done
if test "X$vpn_ip" = "X"
then
    echo "ERROR: VPN IP not found from routes."
    exit 1
fi

iptables -F
iptables -P INPUT DROP
iptables -P OUTPUT DROP
ip6tables -F
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
lanstate="blocked"
if test "X$subnet" != "X"
then
    lannet=0
    if test "X$subnet" = "X192"
    then
        lannet=168
    fi
    lanstate="allowed"
    iptables -A INPUT -s $subnet.$lannet.0.0/16 -d $subnet.$lannet.0.0/16 -j ACCEPT
    iptables -A OUTPUT -s $subnet.$lannet.0.0/16 -d $subnet.$lannet.0.0/16 -j ACCEPT
fi
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A OUTPUT -o tun+ -j ACCEPT
iptables -A INPUT -p udp --sport 1194 -s $vpn_ip -j ACCEPT
iptables -A OUTPUT -p udp --dport 1194 -d $vpn_ip -j ACCEPT
echo "Created iptables filters. LAN connections are $lanstate."
echo "Firewall is active."

function killvpn() {
    echo -e "\nKilling VPN connection..."
}

while [ 1 ]
do
    trap killvpn 2
    wait
    echo -e "\nVPN connection lost. Reconnecting in 5 seconds..."
    echo "To cancel, press c."
    read -s -N 1 -t 5 cancel
    trap 2

    if test "X$cancel" = "Xc"
    then
        break
    fi

    iptables -A INPUT -p udp --sport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    echo "DNS traffic outside VPN tunnel is now allowed."

    num_routes=$(ip route show | wc -l)
    echo -n "Reconnecting VPN..."
    openvpn $1 &>$logfile &
    wait_routes $num_routes -1
    echo -e "\n\nVPN connection is active."

    iptables -D INPUT -p udp --sport 53 -j ACCEPT
    iptables -D OUTPUT -p udp --dport 53 -j ACCEPT
    echo "DNS traffic outside VPN tunnel is now blocked."
done

iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
ip6tables -F
ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
echo -e "\nFlushed iptables filter chain. Firewall is disabled."
sleep 1
