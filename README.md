# README

Minimal example to reproduce invalid WCS Geotif output on the AHN3 WCS services. The weird thing is that it occurs when doing a GetCoverage v2.0.1 request, but not when doing a GetCoverage v1.0.0 request.

THis behaviour can be seen on our production service `https://service.pdok.nl/rws/ahn3/wcs/v1_0` by running the `do-getcov-req.sh` script without any arguments:

```sh
./do-getcov-req.sh
```

Also it only occurs when run under Docker but not when running in a docker-compose setup.

To reproduce run the following:

- Docker: `./run-docker.sh`
- docker-compose: `./run-docker-compose.sh`

The invalid Geotif output is detected by attempting to re-exporting the Geotif with gdal in the `do-getcov-req.sh` script.

The invalid Geotif will produce the following error message when opened with gdal_translate:

```
ERROR 1: TIFFFillStrip:Read error at scanline 792; got 2896 bytes, expected 4256
ERROR 1: TIFFReadEncodedStrip() failed.
ERROR 1: /tmp/tmp.LpYBfHLOp7.tif, band 1: IReadBlock failed at X offset 0, Y offset 397: TIFFReadEncodedStrip() failed.
```

A valid Geotiff should produce the following output:

```
> v1 wcs request - succesfully converted tif to cog: /tmp/tmp.8KvejgFp8j.cog.tif
```
