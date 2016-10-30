#!/bin/sh
# When using a dynamic IP and a router that asks for a password every time to see the status page,
# access that page and grep the IP address for upload to a public site.
# Useful when gaming with friends.

echo "Enter router password (won't be echoed)."
stty_orig=`stty -g`
stty -echo
read pw
stty $stty_orig 

ip=$(wget http://10.0.0.1/adm/status.asp --user=panther --password=$pw -q -O - | grep 'id="idv4wanip"' | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

if test "X$ip" == "X"
then
    echo "Error."
    exit
fi

echo
echo WAN IP: $ip
echo
echo -n "Press return to publish WAN IP."
read

# Upload contents of $ip variable somewhere publicly available in the script.
source ~/.localscripts/publiship.sh 2>/dev/null

echo "Done."

