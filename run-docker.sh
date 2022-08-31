#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
IMAGE=${1:-PDOK}

CONTAINER_NAME=mapserver-wcs-issue
docker stop "$CONTAINER_NAME" &> /dev/null

set -euo pipefail

if [[ $IMAGE == "PDOK" ]];then
    VERSION=7.6.4-patch5-buster-lighttpd-nl #- ISSUE OCCURS
    # VERSION=7.6.4-lighttpd - ISSUE OCCURS
    # VERSION=7.6.1-lighttpd - ISSUE OCCURS
    # VERSION=7.4-lighttpd - ISSUE OCCURS
    docker run \
        --rm \
        -d \
        -e MS_MAPFILE=/etc/service.map \
        -p 80:80 \
        --name $CONTAINER_NAME \
        -v `pwd`:/srv \
        -v `pwd`/service.map:/etc/service.map \
        pdok/mapserver:$VERSION > /dev/null
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

QUERY_STRING_201="&version=2.0.1&request=GetCoverage&service=WCS&CoverageID=ahn3_5m_dtm&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x(1000),y(1000)&subset=x(231620,235620)&subset=y(580897,584897)"


QUERY_STRING_100="SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=ahn3_5m_dtm&BBOX=231620,580897,235620,584897&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=1000&HEIGHT=1000&INTERPOLATION=bilinear"

# do requests using mapserv binary

output_cog_file_201=$(mktemp --suffix=.cog.tif)
output_tif_file_201=$(mktemp --suffix=.tif)
output_file_201=$(mktemp)

output_cog_file_100=$(mktemp --suffix=.cog.tif)
output_tif_file_100=$(mktemp --suffix=.tif)

echo "mapserv -nh QUERY_STRING=\"${QUERY_STRING_201}\" > /tmp/output_wcs_getcov_201"
docker exec -e QUERY_STRING="$QUERY_STRING_201" -it $CONTAINER_NAME bash -c "mapserv -nh QUERY_STRING=\"${QUERY_STRING_201}\" > /tmp/output_wcs_getcov_201"
docker exec -e QUERY_STRING="$QUERY_STRING_100" -it $CONTAINER_NAME bash -c "mapserv -nh QUERY_STRING=\"${QUERY_STRING_100}\" > /tmp/output_wcs_getcov_100.tif"
docker cp $CONTAINER_NAME:/tmp/output_wcs_getcov_201 "$output_file_201"
docker cp $CONTAINER_NAME:/tmp/output_wcs_getcov_100.tif "$output_tif_file_100"

if [[ $IMAGE == "PDOK" ]];then
    "${SCRIPT_DIR}/split-multipart.sh" "$output_file_201" "$output_tif_file_201"
else
    mv "$output_file_201" "$output_tif_file_201"
fi

gdal_translate -r bilinear -of COG -co COMPRESS=DEFLATE "$output_tif_file_100" "$output_cog_file_100" > /dev/null
echo "> v1 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file_100}"


gdal_translate -r bilinear -of COG -co COMPRESS=DEFLATE "$output_tif_file_201" "$output_cog_file_201" > /dev/null
echo "> v2 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file_201}"
echo ""
echo "diff <(gdalinfo -stats ${output_cog_file_100}) <(gdalinfo -stats ${output_cog_file_201})"
# show logs
# docker logs $CONTAINER_NAME

# stop and remove container
# docker stop $CONTAINER_NAME
