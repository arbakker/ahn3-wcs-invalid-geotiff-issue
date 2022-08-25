#!/usr/bin/env bash
docker run \
    --rm \
    -d \
    -e MS_MAPFILE=/srv/service.map \
    -e CPL_VSIL_CURL_CHUNK_SIZE="1048576" \
    -e GDAL_INGESTED_BYTES_AT_OPEN="32768" \
    -e CPL_VSIL_CURL_CACHE_SIZE="1887436800" \
    -p 80:80 \
    --name mapserver-example \
    -v `pwd`:/srv \
    -v `pwd`/service.map:/etc/service.map \
    pdok/mapserver:7.6.4-patch5-buster-lighttpd-nl

# do requests
./do-getcov-req.sh http://localhost

# show logs
# docker logs mapserver-example
