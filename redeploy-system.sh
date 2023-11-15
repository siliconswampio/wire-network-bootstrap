#!/bin/sh

IMAGE_NAME="bios"  # replace with your image name
CONTAINER_ID=$(docker ps -qf "name=$IMAGE_NAME")

echo "Container ID '$CONTAINER_ID'"

if [ "$CONTAINER_ID" != "" ]; then
    docker exec -it $CONTAINER_ID cleos -u https://f0a4-172-109-209-165.ngrok-free.app/ set contract eosio /opt/eosio.contracts/build/contracts/eosio.system/ -x 3600
else
    echo "No running containers found for image $IMAGE_NAME"
fi