#!/bin/sh
# When using a dynamic IP and a router that asks for a password every time to see the status page,
# access that page and grep the IP address for upload to a public site.
# This is useful when gaming with friends or you need to publish your IP for other reasons.
# The script supports the following router models:
#    1. TW-LTE/4G/3G router, WiFI AC
#    2. FAST3686 (DNA Valokuitu Plus)

routermodel=2
lanip=10.0.0.1

if test "$routermodel" = 1
then
    echo "Enter router password (won't be echoed)."
    stty_orig=`stty -g`
    stty -echo
    read pw
    stty $stty_orig 
    username=$(whoami)
    wanipv4=$(wget http://$lanip/adm/status.asp --user=$username --password=$pw -q -O - | grep 'id="idv4wanip"' | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
elif test "$routermodel" = 2
then
    wanipv4=$(wget http://$lanip/RgSetup.asp -q -O - | grep -o "id=\"wanipaddr[^<]*" | cut -f 2 -d '>')
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
