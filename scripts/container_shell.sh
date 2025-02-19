#!/usr/bin/sh
# List running containers and select one where to run an interactive shell, or alternatively the command given in $1.
# Both Podman and Docker work if not aliased.

cmd=${1:-/bin/sh}
manager=docker
[ "$(which podman 2>/dev/null)" ] && manager="podman"

containers=$($manager ps --format "table {{.ID}} {{.Names}}" | grep -A 99 "CONTAINER ID NAMES")

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

echo -n "Exec $cmd in container with order number: "
read selection

selection=$(echo $selection | tr -c -d [:digit:])
! [ "$selection" ] && exit 1

head_index=$(expr $selection + 1)
container_id=$(echo "$containers" | head -n $head_index | tail -n 1 | cut -f -1 -d ' ')
$manager exec -it $container_id "$cmd"
