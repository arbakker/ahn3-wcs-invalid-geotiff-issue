#!/usr/bin/env bash
set -euo pipefail

SERVICE_URL="${1}"
COVERAGE_ID="${2:-ahn3_5m_dtm}"

bbox=231620,580897,235620,584897

IFS=, read -r minx miny maxx maxy <<< "$bbox"
scale_x=1000
scale_y=1000

query_v2="version=2.0.1&request=GetCoverage&service=WCS&CoverageID=${COVERAGE_ID}&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x($scale_x),y($scale_y)&subset=x($minx,$maxx)&subset=y($miny,$maxy)"
query_v1="SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=${COVERAGE_ID}&BBOX=${bbox}&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=${scale_x}&HEIGHT=${scale_y}"

# v1
echo "#### WCS V1 ####"
echo 
local_url="${SERVICE_URL}?${query_v1}"
echo "$local_url"
content_type=$(curl -s -w "%{content_type}" $local_url -o /dev/null)
echo "> v1 wcs request - response content-type: ${content_type}"
echo

# v2
echo "#### WCS V2 ####"
echo 
local_url="${SERVICE_URL}?${query_v2}"
echo "$local_url"
content_type=$(curl -s -w "%{content_type}" $local_url -o /dev/null)
echo "> v2 wcs request - response content-type: ${content_type}"