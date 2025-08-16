#!/usr/bin/sh
# When using a router with dynamic WAN IPv4 address, access router status page and get the address.
# Supports the following sources (pass as parameter):
#    ipinfo: Do not use the router, instead use ipinfo.io (default)
#    tw: Telewell TW-LTE/4G/3G router, WiFI AC
#    fast: Sagemcom FAST3686 (DNA Valokuitu Plus)

ipsource=${1:-ipinfo}
username=${2:-admin}
routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

readpw() {
    if [ -e ~/.config/router_password ]
    then
        pw=$(cat ~/.config/router_password)
        return
    fi
    echo "Enter router password (won't be echoed)."
    stty_orig=$(stty -g)
    stty -echo
    read pw
    stty $stty_orig
}

if [ "$ipsource" = "ipinfo" ]
then
    wanipv4=$(wget https://ipinfo.io/ip -q -O -)
elif [ "$ipsource" = "tw" ]
then
    readpw
    # Sometimes the router gives an unauthorized error a few times.
    tries=10
    while [ $tries -gt 0 ]
    do
        wanipv4=$(wget http://$routerip/adm/status.asp --user=$username --password=$pw -q -O - \
            | grep "\(id=\"idv4wanip\"\)\|\(Document Error\)" \
            | grep -o "\(Error\)\|\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)")
        if [ "$wanipv4" = "Error" ]
        then
            tries=$(expr $tries - 1)
            wanipv4=""
            sleep 1
        else
            break
        fi
    done
elif [ "$ipsource" = "fast" ]
then
    # Check if login is needed. The router remembers logged in computers with some kind of logic.
    responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    if [ "$(echo $responsepage | grep loginUsername)" ]
    then
        readpw
        echo "Logging in..."
        skey=$(echo $responsepage | grep -o "SessionKey = [0-9]*;" | tr -dc "[:digit:]")
        wget -q -O /dev/null "http://$routerip/goform/login?sessionKey=$skey" \
            --post-data="loginUsername=$username&loginPassword=$pw"
        responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    fi
    wanipv4=$(echo $responsepage | grep -o "id=\"wanipaddr[^<]*" | cut -f 2 -d '>')
    ipv6_prefix=$(echo $responsepage | grep -o "IPv6 Prefix:[^0-9]\{1,\}>[^/]\{1,\}" | grep -o ">[0-9a-f:].*" | tr -d '>')
fi

echo "WAN IPv4: $wanipv4"
echo "IPv6 prefix: $ipv6_prefix"
echo

[ ! "$wanipv4" ] && echo "Error retrieving IPv4." && exit 1

# Use a secret script to upload IP info somewhere publicly available.
if [ -e ~/.scripts_extra/publish_ip.sh ]
then
    echo Press return to publish WAN IPv4 and IPv6 prefix.
    read tmp

    sh ~/.scripts_extra/publish_ip.sh $wanipv4 $ipv6_prefix 2>/dev/null

    echo Done.
fi
