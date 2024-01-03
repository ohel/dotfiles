# Toggles Docker services on/off.
# The critical bit is Docker setting a FORWARD policy DROP which would break my virtual machines.
# Other than that, this script mainly just cleans up everything.
#!/bin/sh

if [ "$(which systemctl 2>/dev/null)" ]
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
    sudo iptables -P FORWARD ACCEPT
  fi
else
  if [ "$(/etc/init.d/docker status | grep stopped)" ]
  then
    echo Starting Docker services.
    sudo /etc/init.d/docker start
    sudo iptables -P FORWARD ACCEPT
  else
    stopping=yes
    echo Stopping Docker services.
    sudo /etc/init.d/docker stop
  fi
fi

[ ! "$stopping" ] && exit 0
sudo iptables -t nat -F
sudo iptables -t nat -X DOCKER
sudo iptables -F DOCKER
sudo iptables -F DOCKER-USER
sudo iptables -F DOCKER-ISOLATION-STAGE-1
sudo iptables -F DOCKER-ISOLATION-STAGE-2
sudo iptables -F FORWARD
sudo iptables -X DOCKER
sudo iptables -X DOCKER-USER
sudo iptables -X DOCKER-ISOLATION-STAGE-1
sudo iptables -X DOCKER-ISOLATION-STAGE-2
sudo iptables -P FORWARD ACCEPT
