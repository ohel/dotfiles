#!/usr/bin/sh
# Toggles Docker services on/off.
# The critical bit is Docker setting FORWARD policy DROP.
# That prevents e.g. KVM virtual machine packet routing.
# Other than that, this script just cleans up everything.

if command -v systemctl >/dev/null
then
  if [ "$(systemctl | grep docker | grep -v device)" ]
  then
    stopping=yes
    echo Stopping Docker services.
    sudo systemctl stop docker.service
    sudo systemctl stop docker.socket
    sudo systemctl disable docker.service
    sudo systemctl disable docker.socket
  else
    echo Starting Docker services.
    sudo systemctl enable docker.service
    sudo systemctl enable docker.socket
    sudo systemctl start docker.service
    sudo systemctl start docker.socket
  fi
else
  if [ "$(/etc/init.d/docker status | grep stopped)" ]
  then
    echo Starting Docker services.
    sudo /etc/init.d/docker start
  else
    stopping=yes
    echo Stopping Docker services.
    sudo /etc/init.d/docker stop
  fi
fi

sudo iptables -P FORWARD ACCEPT
[ ! "$stopping" ] && exit 0

sudo iptables -t nat -F 2>/dev/null
sudo iptables -t nat -X DOCKER 2>/dev/null
sudo ip6tables -t nat -F 2>/dev/null
sudo ip6tables -t nat -X DOCKER 2>/dev/null
sudo iptables -F FORWARD 2>/dev/null
sudo nft flush table ip filter 2>/dev/null
sudo nft flush table ip6 filter 2>/dev/null
sudo iptables -X DOCKER 2>/dev/null
sudo iptables -X DOCKER-USER 2>/dev/null
sudo iptables -X DOCKER-FORWARD 2>/dev/null
sudo iptables -X DOCKER-CT 2>/dev/null
sudo iptables -X DOCKER-BRIDGE 2>/dev/null
sudo iptables -X DOCKER-ISOLATION-STAGE-1 2>/dev/null
sudo iptables -X DOCKER-ISOLATION-STAGE-2 2>/dev/null
sudo ip6tables -X DOCKER 2>/dev/null
sudo ip6tables -X DOCKER-USER 2>/dev/null
sudo ip6tables -X DOCKER-FORWARD 2>/dev/null
sudo ip6tables -X DOCKER-CT 2>/dev/null
sudo ip6tables -X DOCKER-BRIDGE 2>/dev/null
sudo ip6tables -X DOCKER-ISOLATION-STAGE-1 2>/dev/null
sudo ip6tables -X DOCKER-ISOLATION-STAGE-2 2>/dev/null

echo "Cleared iptables, check results with: sudo nft list ruleset"
