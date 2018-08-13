#!/bin/sh
# When using a dynamic IP and a router that asks for a password every time to see the status page,
# access that page and grep the IP address for upload to a public site.
# This is useful when gaming with friends or you need to publish your IP for other reasons.
# The script supports the following router models:
#    tw: TW-LTE/4G/3G router, WiFI AC
#    fast: FAST3686 (DNA Valokuitu Plus)

routermodel=${1:-fast}

username=$(whoami)
routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
readpw() {
    echo "Enter router password (won't be echoed)."
    stty_orig=`stty -g`
    stty -echo
    read pw
    stty $stty_orig 
}

if test "$routermodel" = "tw"
then
    readpw
    wanipv4=$(wget http://$routerip/adm/status.asp --user=$username --password=$pw -q -O - | grep 'id="idv4wanip"' | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
elif test "$routermodel" = "fast"
then
    # Check if login is needed. The router remembers logged in computers with some kind of logic.
    responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    if test "X$(echo $responsepage | grep loginUsername)" != "X";
    then
        username=admin
        readpw
        skey=$(echo $responsepage | grep -o "SessionKey = [0-9]*;" | tr -dc "[:digit:]")
        wget -q -O /dev/null "http://$routerip/goform/login?sessionKey=$skey" --post-data="loginOrInitDS=0&loginUsername=$username&loginPassword=$pw&currentDsFrequency=450000000&currentUSChannelID=2"
        responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    fi
    wanipv4=$(echo $responsepage | grep -o "id=\"wanipaddr[^<]*" | cut -f 2 -d '>')
fi

echo
echo WAN IPv4: $wanipv4
echo

if test "X$wanipv4" = "X"
then
    echo "Error."
    exit
fi

# Use a secret script to upload contents of $ip variable somewhere publicly available.
if [ -e ~/.scripts_extra/publish_ip.sh ]
then
    echo -n "Press return to publish WAN IPv4."
    read

    sh ~/.scripts_extra/publish_ip.sh $wanipv4 2>/dev/null

    echo "Done."
fi
