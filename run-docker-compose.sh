#!/usr/bin/env bash

docker-compose up -d
sleep 5
docker-compose logs do-requests

# inspect mapserver logs
# docker-compose logs wcs
