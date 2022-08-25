#!/usr/bin/env bash

docker-compose up -d
sleep 10
docker-compose logs do-requests

# inspect mapserver logs
# docker-compose logs wcs
