FROM osgeo/gdal:ubuntu-small-3.5.1 as builder
SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

RUN apt-get update \
    && apt-get upgrade --assume-yes \
    && LC_ALL=C apt-get install --assume-yes --no-install-recommends bison \
    flex python-lxml libfribidi-dev swig \
    cmake librsvg2-dev colordiff libpq-dev libpng-dev libjpeg-dev libgif-dev libgeos-dev libgd-dev \
    libfreetype6-dev libfcgi-dev libcurl4-gnutls-dev libcairo2-dev libxml2-dev \
    libxslt1-dev python-dev php-dev libexempi-dev lcov lftp ninja-build git curl \
    clang libprotobuf-c-dev protobuf-c-compiler libharfbuzz-dev libcairo2-dev librsvg2-dev \
    && ln -s /usr/local/lib/libproj.so.* /usr/local/lib/libproj.so

ARG MAPSERVER_BRANCH=branch-7-6
ARG MAPSERVER_REPO=https://github.com/mapserver/mapserver

RUN git clone ${MAPSERVER_REPO} --branch=${MAPSERVER_BRANCH} --depth=100 /src

COPY checkout_release /tmp
RUN cd /src \
    && /tmp/checkout_release ${MAPSERVER_BRANCH}


WORKDIR /src/build
RUN cmake .. \
    -GNinja \
    -DCMAKE_C_FLAGS="-O2 -DPROJ_RENAME_SYMBOLS" \
    -DCMAKE_CXX_FLAGS="-O2 -DPROJ_RENAME_SYMBOLS" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DWITH_CLIENT_WMS=1 \
    -DWITH_CLIENT_WFS=1 \
    -DWITH_OGCAPI=1 \
    -DWITH_KML=1 \
    -DWITH_SOS=1 \
    -DWITH_XMLMAPFILE=1 \
    -DWITH_POINT_Z_M=1 \
    -DWITH_CAIRO=1 \
    -DWITH_RSVG=1 \
    -DUSE_PROJ=1 \
    -DUSE_WFS_SVR=1 \
    -DUSE_OGCAPI_SVR=1 \
    -DWITH_ORACLESPATIAL=0

RUN ninja install

FROM osgeo/gdal:ubuntu-small-3.5.1 as runner


# Let's copy a few of the settings from /etc/init.d/apache2
ENV MS_MAP_PATTERN=^\\/etc\\/mapserver\\/([^\\.][-_A-Za-z0-9\\.]+\\/{1})*([-_A-Za-z0-9\\.]+\\.map)$

RUN apt-get update \
    && apt-get upgrade --assume-yes \
    && apt-get install --assume-yes --no-install-recommends ca-certificates curl \
    libfribidi0 librsvg2-2 libpng16-16 libgif7 libfcgi0ldbl \
    libxslt1.1 libprotobuf-c1 libcap2-bin libaio1


RUN && mkdir /etc/mapserver \
    && mkdir --parent /etc/mapserver

EXPOSE 8080
COPY --from=builder /usr/local/bin /usr/local/bin/
COPY --from=builder /usr/local/lib /usr/local/lib/
COPY --from=builder /usr/local/share/mapserver /usr/local/share/mapserver/

COPY runtime /

RUN ldconfig

ENV MS_DEBUGLEVEL=0 \
    MS_ERRORFILE=stderr \
    MAPSERVER_CONFIG_FILE=/etc/mapserver.conf \
    MAX_REQUESTS_PER_PROCESS=1000 \
    MIN_PROCESSES=1 \
    MAX_PROCESSES=5 \
    BUSY_TIMEOUT=300 \
    IDLE_TIMEOUT=300 \
    IO_TIMEOUT=40 \
    GET_ENV=env

RUN adduser www-data root 
WORKDIR /etc/mapserver
