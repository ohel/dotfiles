#!/bin/sh
# When using a dynamic IP and a router that asks for a password every time to see the status page,
# access that page and grep the IP address for upload to a public site.
# This is useful when gaming with friends or you need to publish your IP for other reasons.
# Currently the script supports the following router: TW-LTE/4G/3G router, WiFI AC

echo "Enter router password (won't be echoed)."
stty_orig=`stty -g`
stty -echo
read pw
stty $stty_orig 

username=$(whoami)
ip=$(wget http://10.0.0.1/adm/status.asp --user=$username --password=$pw -q -O - | grep 'id="idv4wanip"' | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

if test "X$ip" == "X"
then
    echo "Error."
    exit
fi

echo
echo WAN IP: $ip
echo

# Use a secret script to upload contents of $ip variable somewhere publicly available.
if [ -e ~/.scripts_extra/publish_ip.sh ]
then
    echo -n "Press return to publish WAN IP."
    read

    sh ~/.scripts_extra/publish_ip.sh $ip 2>/dev/null

    echo "Done."
fi
