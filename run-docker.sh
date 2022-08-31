#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
IMAGE=${1:-PDOK}
CONTAINER_NAME=mapserver-wcs-issue

source $SCRIPT_DIR/docker-image.sh # LOAD DOCKER_IMAGE env var

docker stop "$CONTAINER_NAME" &> /dev/null

set -euo pipefail

if [[ $IMAGE == "PDOK" ]];then
    docker run \
        --rm \
        -d \
        -e MS_MAPFILE=/etc/service.map \
        -p 80:80 \
        --name $CONTAINER_NAME \
        -v `pwd`:/srv \
        -v `pwd`/service.map:/etc/service.map \
        $DOCKER_IMAGE > /dev/null
else
    # run with camptocamp/mapserver
    VERSION=7.6
    docker run \
        --rm \
        -d \
        -p 80:80 \
        --name $CONTAINER_NAME \
        -v `pwd`:/srv \
        -v `pwd`/service.map:/etc/mapserver/mapserver.map \
        camptocamp/mapserver:$VERSION > /dev/null
fi

if [[ $? -ne 0 ]];then
    echo "failed to run mapserver docker container"
    exit 1
fi

sleep 2

$SCRIPT_DIR/do-getcov-req.sh "./data" "docker" http://localhost
exit 0
