#!/bin/sh
# On a wpa_supplicant based, manually managed system, toggle Wi-Fi SSID on first device named wl.*
# between default $1 (static IP) and alternative $2 (DHCP).
# Use either a single wpa_supplicant.conf ($3 = 0) or multiple with names like wpa_supplicant_ssid.conf ($3 = 1).
#
# If /etc/wpa_supplicant/wpa_supplicant.conf is a symbolic link, multiple config files are assumed,
# the default SSID is read from the config file as the first SSID found, and $1 is used as the alternative SSID.
#
# If alternative SSID is not given, it is read from /etc/wpa_supplicant/alternative.conf.
#
# It's good to have these basic control settings in wpa_supplicant.conf:
#
#    ctrl_interface=/run/wpa_supplicant
#    ctrl_interface_group=wheel

[ "$(echo $HOME)" != "/root" ] && echo Must run using sudo. && exit 1

ssid=$1
alternative=$2
use_multi_conf=${3:-0}

fixed_ip="10.0.0.2/24"
fixed_gateway="10.0.0.1"

nic=$(ip addr | grep "wl.*:" | cut -f 2 -d ':' | tr -d ' ' | head -n 1)

config_file=/etc/wpa_supplicant/wpa_supplicant.conf
[ -L $config_file ] && default=$(grep "[ ]\+ssid=" $config_file 2>/dev/null | head -n 1 | cut -f 2 -d '=' | tr -d '"')

if [ "$default" ]
then
    ssid=$default
    alternative=$1
    use_multi_conf=1
    if [ ! "$alternative" ]
    then
        alternative=$(grep "[ ]\+ssid=" /etc/wpa_supplicant/alternative.conf 2>/dev/null | head -n 1 | cut -f 2 -d '=' | tr -d '"')
    fi
else
    [ ! "$ssid" ] && echo No SSID found or given. && exit 1
    $default=$ssid
fi

# Determine which SSID is in use.
wpa_cli -i $nic -p /run/wpa_supplicant status 2>/dev/null \
    | grep ^ssid=$ssid$ >/dev/null && ssid=$alternative

[ ! "$ssid" ] && echo No alternative SSID found or given. && exit 1

if rc-service wpa_supplicant status >/dev/null 2>&1
then
    echo OpenRC service wpa_supplicant should not be running.
    exit 1
fi

echo "Switching $nic to SSID \"$ssid\""

if [ $use_multi_conf -eq 0 ]
then
    # Map SSID -> network id
    network_id=$(wpa_cli -i "$nic" list_networks | awk -v s="$ssid" '$2==s {print $1}')
    if [ -z "$network_id" ]
    then
        echo "Error: ssid \"$ssid\" not found in wpa_supplicant.conf"
        exit 1
    fi
    pkill -f "dhcpcd.*$nic" 2>/dev/null || true
else
    # Using a one network per config file network id mapping won't be necessary.
    config_dir="/etc/wpa_supplicant"
    conf_file="$config_dir/wpa_supplicant_${ssid}.conf"
    pid_file="/run/wpa_supplicant-${nic}.pid"
    ctrl_path="/run/wpa_supplicant"
    if [ ! -f "$conf_file" ]
    then
        echo "Error: no config file found for SSID at $conf_file"
        exit 1
    fi

    pkill -f "wpa_supplicant.*${nic}" 2>/dev/null || true
    sleep 2
    [ -S "$ctrl_path/${nic}" ] && rm -f "$ctrl_path/${nic}"
    pkill -f "dhcpcd.*$nic" 2>/dev/null || true
fi

ip addr flush dev "$nic"
ip route flush dev "$nic"

if [ $use_multi_conf -eq 0 ]
then
    wpa_cli -i "$nic" select_network "$network_id" > /dev/null
else
    echo "Starting wpa_supplicant with $conf_file..."
    if [ ! -e "$ctrl_path" ]
    then
        mkdir "$ctrl_path"
        chown root:wheel "$ctrl_path"
        chmod g=rx "$ctrl_path"
    fi
    wpa_supplicant -B -i "$nic" -c "$conf_file" -P "$pid_file"
fi

echo -n "Waiting for Wi-Fi association..."
max_wait=60
waited=0
while [ $waited -lt $max_wait ]
do
    status=$(wpa_cli -i "$nic" -p /run/wpa_supplicant status | grep '^wpa_state=' | cut -d '=' -f 2)
    if [ "$status" = "COMPLETED" ]
    then
        echo " done."
        break
    fi
    sleep 1
    waited=$((waited+1))
done
if [ $waited -ge $max_wait ]
then
    echo " timeout waiting for Wi-Fi association."
    exit 1
fi

if [ "$ssid" = "$default" ]
then
    ip addr add $fixed_ip dev "$nic" scope global
    ip route add default via $fixed_gateway dev "$nic"
elif [ "$ssid" = "$alternative" ]
then
    dhcpcd --nohook resolv.conf "$nic" &
    max_wait=60
    waited=0
    while [ $waited -lt $max_wait ]
    do
        status=$(ip addr show "$nic" | grep "inet ")
        if [ "$status" ];
        then break
        fi
        sleep 1
        waited=$((waited+1))
    done
    if [ $waited -ge $max_wait ]
    then
        echo "Timeout waiting for DHCP."
        exit 1
    fi
else
    echo "Error: SSID \"$ssid\" not known by script."
fi

echo "New IP configuration:"
ip addr show $nic | tail -n 2 | head -n 1
