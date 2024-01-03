# Toggles Docker services on/off.
# Docker tends to break iptables so that my virtual machine networks don't work anymore.
# Haven't yet figured out if they can work together, so created this toggle script instead for now.
#!/bin/sh

if [ "$(which systemctl 2>/dev/null)" ]
then
  if [ "$(systemctl | grep docker | grep -v device)" ]
  then
    echo Stopping Docker services.
    sudo systemctl stop docker.service
    sudo systemctl stop docker.socket
    sudo systemctl disable docker.service
    sudo systemctl disable docker.socket
    sudo iptables -t nat -F
    sudo iptables -t nat -X DOCKER
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
    echo Stopping Docker services.
    sudo /etc/init.d/docker stop
    sudo iptables -t nat -F
    sudo iptables -t nat -X DOCKER
  fi
fi
