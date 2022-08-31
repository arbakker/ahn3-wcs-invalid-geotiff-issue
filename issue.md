# MapServer WCS 2.0.1 GetCoverage request results in corrupt geotiff

I ran into the following curious issue; a WCS 2.0.1 GetCoverage request results in a corrupt geotiff file, while a WCS 1.0.0 GetCoverage result in a valid geotiff file. 

This only occurs when running the [pdok/mapserver-docker](https://github.com/PDOK/mapserver-docker/) image, I could not reproduce it with the 
[camptocamp/docker-mapserver](https://github.com/camptocamp/docker-mapserver) image. 


This behaviour can be seen by running the [`do-get-cov-req.sh`](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue/blob/main/do-getcov-req.sh) script from the [arbakker/ahn3-wcs-invalid-geotiff-issue](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue) repo, this issues GetCoverage request against `https://service.pdok.nl/rws/ahn3/wcs/v1_0`:

```sh
./do-getcov-req.sh
# #### WCS V1 ####
# 
# > downloading tif from https://service.pdok.nl/rws/ahn3/wcs/v1_0?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=ahn3_5m_dtm&BBOX=231520,580797,235720,584997&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=1000&HEIGHT=1000 to /tmp/tmp.QiAZAOD42J.tif
# > v1 wcs request - succesfully converted tif to cog with gdal_translate: /tmp/tmp.VoFkJVbfjN.cog.tif
# 
# #### WCS V2 ####
# 
# > downloading tif from https://service.pdok.nl/rws/ahn3/wcs/v1_0?version=2.0.1&request=GetCoverage&service=WCS&CoverageID=ahn3_5m_dtm&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x(1000),y(1000)&subset=x(231520,235720)&subset=y(580797,584997) to /tmp/tmp.QXauXcc5hM.tif
# ERROR 1: TIFFFillStrip:Read error at scanline 772; got 246 bytes, expected 4075
# ERROR 1: TIFFReadEncodedStrip() failed.
# ERROR 1: /tmp/tmp.QXauXcc5hM.tif, band 1: IReadBlock failed at X offset 0, Y offset 387: TIFFReadEncodedStrip() failed.
```

I created a minimal example with configuration and data in the aforementioned [repository](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue). 

To reproduce the issue clone the [repository](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue) and run from the root of the repository:

```sh
./run-docker.sh
# #### WCS V1 ####
# 
# > downloading tif from http://localhost?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=ahn3_5m_dtm&BBOX=231520,580797,235720,584997&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=1000&HEIGHT=1000 to /tmp/tmp.9rH86snOlF.tif
# > v1 wcs request - succesfully converted tif to cog with gdal_translate: /tmp/tmp.wKHv9I4XoI.cog.tif
# 
# #### WCS V2 ####
# 
# > downloading tif from http://localhost?version=2.0.1&request=GetCoverage&service=WCS&CoverageID=ahn3_5m_dtm&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x(1000),y(1000)&subset=x(231520,235720)&subset=y(580797,584997) to /tmp/tmp.0QZ9XOXDqd.tif
# ERROR 1: TIFFFillStrip:Read error at scanline 792; got 2896 bytes, expected 4256
# ERROR 1: TIFFReadEncodedStrip() failed.
# ERROR 1: /tmp/tmp.0QZ9XOXDqd.tif, band 1: IReadBlock failed at X offset 0, Y offset 397: TIFFReadEncodedStrip() failed.
```

This script will start up the MapServer Docker container and issue two WCS GetCoverage requests which only differ in version, see the above ouput.

The Geotiff produced by the v1.0.0 WCS GetCoverage request can be read by `gdal_translate`, the Geotiff produced by the v2.0.1 WCS GetCoverage requests cannot be read by `gdal_translate`; the file is corrupt.

On top of that I also found that the config and data in this example does not exhibit the same behaviour when run with docker-compose. When run with docker-compose the v2.0.1 WCS GetCoverage request produces a Geotiff file that `gdal_translate` can read. To reproduce this run the `./run-docker-compose.sh` script from the aforementioned repository:

```sh
./run-docker-compose.sh
# Creating network "ahn3-wcs-2-invalid-tif-issue_default" with the default driver
# Creating ahn3-wcs-2-invalid-tif-issue_wcs_1 ... done
# Creating ahn3-wcs-2-invalid-tif-issue_do-requests_1 ... done
# Attaching to ahn3-wcs-2-invalid-tif-issue_do-requests_1
# do-1requests_1  | #### WCS V1 ####
# do-requests_1  | 
# do-requests_1  | > downloading tif from http://wcs?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=ahn3_5m_dtm&BBOX=231520,580797,235720,584997&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=1000&HEIGHT=1000 to /tmp/tmp.IAIJ4yYTiJ.tif
# do-requests_1  | > v1 wcs request - succesfully converted tif to cog with gdal_translate: /tmp/tmp.hReiBCQIOE.cog.tif
# do-requests_1  | 
# do-requests_1  | #### WCS V2 ####
# do-requests_1  | 
# do-requests_1  | > downloading tif from http://wcs?version=2.0.1&request=GetCoverage&service=WCS&CoverageID=ahn3_5m_dtm&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x(1000),y(1000)&subset=x(231520,235720)&subset=y(580797,584997) to /tmp/tmp.deyOkCCZNj.tif
# do-requests_1  | > v2 wcs request - succesfully converted tif to cog with gdal_translate: /tmp/tmp.yvUzCWoSf0.cog.tif
```

Both examples ([docker](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue/blob/main/run-docker.sh) and [docker-compose](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue/blob/main/run-docker-compose.sh)) share the same [mapfile](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue/blob/main/service.map) and [data](https://github.com/arbakker/ahn3-wcs-invalid-geotiff-issue/blob/main/data/data.tif). Which makes me suspect the issue is caused by something in the environment MapServer runs in.


See below the mapserver logs produced when runing the `./run-docker.sh` script (which produces the corrupt Geotiff with the v2.0.1 GetCoverage request):

```log
2022-08-26 17:25:25: (server.c.1464) server started (lighttpd/1.4.53-devel-lighttpd-1.4.53) 
[Fri Aug 26 15:25:25 2022].447484: GDAL: GDALOpen(/srv/data/data.tif, this=0x561f823367a0) succeeds as GTiff.
[Fri Aug 26 15:25:25 2022].457060: GDAL: GDAL_CACHEMAX = 785 MB
[Fri Aug 26 15:25:25 2022].562657: GDAL: GDALDriver::Create(MEM,msSaveImageGDAL_temp,1000,1000,1,Float32,(nil))
[Fri Aug 26 15:25:25 2022].567874: MDReaderPleiades: Not a Pleiades product
[Fri Aug 26 15:25:25 2022].567889: MDReaderPleiades: Not a Pleiades product
[Fri Aug 26 15:25:25 2022].567922: GDAL: GDALDatasetCopyWholeRaster(): 1000*1000 swaths, bInterleave=0
[Fri Aug 26 15:25:25 2022].570350: GDAL: GDALClose(msSaveImageGDAL_temp, this=0x561f8232be60)
[Fri Aug 26 15:25:25 2022].666692: GDAL: GDALClose(/vsimem/msout/6308e5e5_7_0.tif, this=0x561f826a97f0)
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: CGI Request 1 on process 7
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: msWCSParseRequest(): request is KVP.
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: msDrawRasterLayerLow(ahn3_5m_dtm): entering.
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: msSaveImage(stdout) total time: 0.106s
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: mapserv request processing time (msLoadMap not incl.): 0.223s
2022-08-26 17:25:25: (mod_fastcgi.c.421) FastCGI-stderr: msFreeMap(): freeing map at 0x561f822af250.
172.17.0.1 localhost - [26/Aug/2022:17:25:25 +0200] "GET /?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage&FORMAT=GEOTIFF_FLOAT32&COVERAGE=ahn3_5m_dtm&BBOX=231520,580797,235720,584997&CRS=EPSG:28992&RESPONSE_CRS=EPSG:28992&WIDTH=1000&HEIGHT=1000 HTTP/1.1" 200 2697015 "-" "curl/7.81.0"
[Fri Aug 26 15:25:25 2022].913579: GDAL: GDALClose(/srv/data/data.tif, this=0x561f823367a0)
[Fri Aug 26 15:25:25 2022].913688: GDAL: GDALDriver::Create(MEM,msSaveImageGDAL_temp,1000,1000,1,Float32,(nil))
[Fri Aug 26 15:25:25 2022].915653: GDAL: GDALDatasetCopyWholeRaster(): 1000*1000 swaths, bInterleave=0
[Fri Aug 26 15:25:25 2022].918152: GDAL: GDALClose(msSaveImageGDAL_temp, this=0x561f8232c030)
[Fri Aug 26 15:25:26 2022].068062: GDAL: GDALClose(/vsimem/wcsout/6308e5e5_7_1./out.tif, this=0x561f8232c1c0)
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: CGI Request 2 on process 7
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: Subset for X-axis found: x
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: Subset for Y-axis found: y
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msWCSGetCoverage20(): Set parameters from originaldata. Width: 1000, height: 1000, cellsize: 4.000000, extent: 231622.000000,580899.000000,235618.000000,584895.000000
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msDrawRasterLayerLow(ahn3_5m_dtm): entering.
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msSaveImage(/vsimem/wcsout/6308e5e5_7_1./out.tif) total time: 0.154s
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msWCSWriteFile20(): force multipart output without gml summary because we have multiple files in the result.
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: mapserv request processing time (
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msLoadMap not incl.): 0.207s
2022-08-26 17:25:26: (mod_fastcgi.c.421) FastCGI-stderr: msFreeMap(): freeing map at 0x561f822af250.
172.17.0.1 localhost - [26/Aug/2022:17:25:26 +0200] "GET /?version=2.0.1&request=GetCoverage&service=WCS&CoverageID=ahn3_5m_dtm&crs=http://www.opengis.net/def/crs/EPSG/0/28992&format=image/tiff&scalesize=x(1000),y(1000)&subset=x(231520,235720)&subset=y(580797,584997) HTTP/1.1" 200 2346019 "-" "curl/7.81.0"
```
