#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
SERVICE_URL="${1:-https://service.pdok.nl/rws/ahn3/wcs/v1_0}"
COVERAGE_ID="${2:-ahn3_5m_dtm}"

bbox=231520,580797,235720,584997 # 100 bigger
    
IFS=, read -r minx miny maxx maxy <<< "$bbox"
scale_x=1000
scale_y=1000

query_v2="version=2.0.1&request=GetCoverage&service=WCS&CoverageID=${COVERAGE_ID}&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x($scale_x),y($scale_y)&subset=x($minx,$maxx)&subset=y($miny,$maxy)"

query_v1="SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=${COVERAGE_ID}&BBOX=${bbox}&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=${scale_x}&HEIGHT=${scale_y}"

# v1
echo "#### WCS V1 ####"
echo 
local_url="${SERVICE_URL}?${query_v1}"
output_tif_file=$(mktemp --suffix=.tif)
output_cog_file=$(mktemp --suffix=.cog.tif)
echo "> downloading tif from ${local_url} to ${output_tif_file}"
curl -s $local_url -o $output_tif_file
gdal_translate -r bilinear -of COG -co COMPRESS=DEFLATE $output_tif_file $output_cog_file > /dev/null
echo "> v1 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file}"
echo 

# v2
echo "#### WCS V2 ####"
echo 
local_url="${SERVICE_URL}?${query_v2}"
output_tif_file=$(mktemp --suffix=.tif)
output_cog_file=$(mktemp --suffix=.cog.tif)
echo "> downloading tif from ${local_url} to ${output_tif_file}"
curl -s $local_url | "${SCRIPT_DIR}/split-multipart.sh" - $output_tif_file
gdal_translate -r bilinear -of COG -co COMPRESS=DEFLATE $output_tif_file $output_cog_file > /dev/null
echo "> v2 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file}"
