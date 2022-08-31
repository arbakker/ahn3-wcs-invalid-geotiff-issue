#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
source $SCRIPT_DIR/docker-image.sh

export DOCKER_IMAGE
docker-compose up -d
sleep 5
docker-compose logs do-requests

# inspect mapserver logs
# docker-compose logs wcs
