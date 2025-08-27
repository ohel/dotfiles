#!/usr/bin/sh
# List running containers and select one where to run an interactive shell, or alternatively the command given in $1.
# Both Docker and Podman work (if not aliased already).

cmd=${1:-/bin/sh}

manager="" && [ "$(which docker 2>/dev/null)" ] && manager="docker"
[ "$manager" ] && containers=$($manager ps --format "table {{.ID}} {{.Names}}" | grep -A 99 "CONTAINER ID NAMES")

# If no docker containers are found, try podman.
if [ ! "$containers" ] || [ $(echo "$containers" | wc -l) -eq 1 ]
then
    manager="" && [ "$(which podman 2>/dev/null)" ] && manager="podman"
    [ "$manager" ] && containers=$($manager ps --format "table {{.ID}} {{.Names}}" | grep -A 99 "CONTAINER ID NAMES")
fi

if [ ! "$containers" ] || [ $(echo "$containers" | wc -l) -eq 1 ]
then
    echo "No running containers."
    exit 0
fi

count=$(echo "$containers" | wc -l)

index=1
while [ $index -lt $count ]
do
    head_index=$(expr $index + 1)
    echo $index: $(echo "$containers" | head -n $head_index | tail -n 1)
    index=$(expr $index + 1)
done

printf "Exec %s in container with order number: " "$cmd"
read selection

selection=$(echo $selection | tr -c -d [:digit:])
! [ "$selection" ] && exit 1

head_index=$(expr $selection + 1)
container_id=$(echo "$containers" | head -n $head_index | tail -n 1 | cut -f -1 -d ' ')
$manager exec -it $container_id "$cmd"
