#!/bin/sh
# When using a router with dynamic WAN IPv4 address, access router status page and get the address.
# Supports the following router models (pass as parameter):
#    tw: Telewell TW-LTE/4G/3G router, WiFI AC
#    fast: Sagemcom FAST3686 (DNA Valokuitu Plus)

routermodel=${1:-fast}

routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
username=$(whoami)

readpw() {
    if [ -e ~/.config/router_password ]
    then
        pw=$(cat ~/.config/router_password)
        return
    fi
    echo "Enter router password (won't be echoed)."
    stty_orig=`stty -g`
    stty -echo
    read pw
    stty $stty_orig
}

if [ "$routermodel" = "tw" ]
then
    readpw
    wanipv4=$(wget http://$routerip/adm/status.asp --user=$username --password=$pw -q -O - \
        | grep 'id="idv4wanip"' \
        | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
elif [ "$routermodel" = "fast" ]
then
    # Check if login is needed. The router remembers logged in computers with some kind of logic.
    responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    if [ "$(echo $responsepage | grep loginUsername)" ]
    then
        username=admin
        readpw
        echo "Logging in..."
        skey=$(echo $responsepage | grep -o "SessionKey = [0-9]*;" | tr -dc "[:digit:]")
        wget -q -O /dev/null "http://$routerip/goform/login?sessionKey=$skey" \
            --post-data="loginUsername=$username&loginPassword=$pw"
        responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    fi
    wanipv4=$(echo $responsepage | grep -o "id=\"wanipaddr[^<]*" | cut -f 2 -d '>')
fi

echo
echo WAN IPv4: $wanipv4
echo

if ! [ "$wanipv4" ]
then
    echo "Error retrieving IPv4."
    exit 1
fi

# Use a secret script to upload contents of $ip variable somewhere publicly available.
if [ -e ~/.scripts_extra/publish_ip.sh ]
then
    echo -n "Press return to publish WAN IPv4."
    read tmp

    sh ~/.scripts_extra/publish_ip.sh $wanipv4 2>/dev/null

    echo "Done."
fi
