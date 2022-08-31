#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
OUTPUT_DIR="${1}"
RUN_TYPE="${2}"
SERVICE_URL="${3}"
COVERAGE_ID="${4:-ahn3_5m_dtm}"

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
output_tif_file=$(mktemp --suffix=.tif)
output_cog_file=$(mktemp --suffix=.cog.tif)
echo "> downloading tif from ${local_url} to ${output_tif_file}"
curl -s $local_url -o $output_tif_file
cp "$output_tif_file" "$OUTPUT_DIR/${RUN_TYPE}_output_100.tif"
gdal_translate -r bilinear -co COMPRESS=DEFLATE $output_tif_file $output_cog_file > /dev/null
echo "> v1 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file}"


# v2
echo "#### WCS V2 ####"
echo 
local_url="${SERVICE_URL}?${query_v2}"
output_multipart_file=$(mktemp --suffix=.multipart)
output_tif_file=$(mktemp --suffix=.tif)
output_cog_file=$(mktemp --suffix=.cog.tif)
echo "> downloading tif from ${local_url} to ${output_multipart_file}"
curl -s $local_url -o $output_multipart_file

$SCRIPT_DIR/split-multipart.sh $output_multipart_file "$output_tif_file"
cp "$output_tif_file" "$OUTPUT_DIR/${RUN_TYPE}_output_201.tif"
gdal_translate -r bilinear -co COMPRESS=DEFLATE $output_tif_file $output_cog_file > /dev/null
echo "> v2 wcs request - succesfully converted tif to cog with gdal_translate: ${output_cog_file}"
