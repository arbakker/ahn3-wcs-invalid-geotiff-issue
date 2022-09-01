#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
CONTAINER_NAME=mapserver-wcs-issue
DOCKER_IMAGE=pdok/mapserver:7.6.4-lighttpd

docker stop "$CONTAINER_NAME" &> /dev/null

set -euo pipefail

docker run \
    --rm \
    -d \
    -e MS_MAPFILE=/etc/service.map \
    -p 80:80 \
    --name $CONTAINER_NAME \
    -v `pwd`:/srv \
    -v `pwd`/service.map:/etc/service.map \
    $DOCKER_IMAGE > /dev/null


if [[ $? -ne 0 ]];then
    echo "failed to run mapserver docker container"
    exit 1
fi

sleep 2

$SCRIPT_DIR/do-getcov-req.sh http://localhost
