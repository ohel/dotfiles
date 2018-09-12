#!/bin/bash
# Reboot an unstable consumer class router.
# Supports the following router models (pass as parameter):
#    fast: Sagemcom FAST3686 (DNA Valokuitu Plus)

routermodel=${1:-fast}

routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

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

echo "Preparing to reboot router at $routerip. Press return to continue."
read

if [ "$routermodel" == "fast" ]
then
    # Check if login is needed. The router remembers logged in computers with some kind of logic.
    responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    if [ "$(echo $responsepage | grep loginUsername)" != "" ]
    then
        username=admin
        readpw
        echo "Logging in..."
        skey=$(echo $responsepage | grep -o "SessionKey = [0-9]*;" | tr -dc "[:digit:]")
        wget -q -O /dev/null "http://$routerip/goform/login?sessionKey=$skey" \
            --post-data="loginUsername=$username&loginPassword=$pw"
    fi
    responsepage=$(wget http://$routerip/RgSetup.asp -q -O -)
    skey=$(echo $responsepage | grep -o "SessionKey = [0-9]*;" | tr -dc "[:digit:]")
    echo Sending reboot request...
    # The WanConnectionType is needed in data, otherwise the request will hang.
    wget -q -O /dev/null "http://$routerip/goform/RgSetup?sessionKey=$skey" \
        --header "Referer: http://$routerip/RgSetup.asp" \
        --post-data="WanConnectionType=0&RebootAction=1"
fi

echo Rebooting...
sleep 30
echo Pinging router...
while [ "$pingresponse" == "" ]
do
    pingresponse=$(ping -c 1 $routerip 2>/dev/null | grep " 0% packet loss")
done
echo Got ping response, router is up. Press return to exit.
read
