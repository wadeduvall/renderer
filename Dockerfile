FROM ubuntu:18.04

# Install dependencies RUN apt update \
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
       git \
       gcc-6 \
       g++-6 \
       python \
       python-dev \
       libxml2 \
       libxml2-dev \
       zlib1g-dev \
       clang \
       make \
       pkg-config \
       curl \
       ca-certificates \
       bash \
       libboost-all-dev \
       libharfbuzz-dev \ 
       apache2 \
       apache2-dev \
       autoconf \
       automake \
       libtool \
       build-essential \
       libcairo2-dev \
       python-cairo-dev \
       libcairomm-1.0-dev \
       libexpat1-dev \
       libfreetype6 \
       libfreetype6-dev \
       libpixman-1-dev \
       fonts-noto-cjk \
       fonts-noto-hinted \
       fonts-noto-unhinted \
       libjpeg-dev \
       libpng-dev \
       libproj-dev \
       libtiff-dev \
       ttf-unifont \
       ttf-dejavu \
       ttf-dejavu-core \
       ttf-dejavu-extra \
       fonts-noto-cjk \
       fonts-noto-hinted \
       fonts-noto-unhinted \
       postgis \
       libgdal-dev \
       gdal-bin \
       libgeos++-dev \
       libgeos-dev
         

RUN apt install -y libmapnik-dev mapnik-utils python3-mapnik
# # Build and insteall mapnik, then clena up (FIXME)
# RUN /bin/bash -c \
#     "git clone https://github.com/mapnik/mapnik \
#     && cd mapnik \
#     && git fetch origin refs/tags/v3.0.23:refs/tags/v3.0.23 \
#     && git checkout v3.0.23 \
#     && git submodule update --init \
#     && . ./bootstrap.sh \
#     && rm -rf .git \
#     && ./configure \
#     && make -j $(nproc) \
#     && make test \
#     && make install"
# 
# # This kills me but seems to be no other way around it without
# # rebuilding everything in mason
# RUN mkdir -p /home/travis/build/mapbox/mason/ \
#     && ln -s /mapnik/mason_packages /home/travis/build/mapbox/mason/ \
#     && mkdir -p /usr/include/mapnik \
#     && ln -s ~/mapnik/include/mapnik/geometry/box2d.hpp /usr/include/mapnik

# Build mod_tile
RUN git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git \
	&& cd mod_tile \
	&& ./autogen.sh \
	&& ./configure \
	&& make -j $(nproc) \
	&& make install \
	&& make install-mod_tile \
	&& ldconfig


RUN apt-get install -y wget \
    && wget --quiet -O - https://deb.nodesource.com/setup_10.x | bash - \
    && apt update \
    && apt install -y nodejs

#COPY project.mml /project.mml

RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git \
    && git -C openstreetmap-carto checkout v4.23.0 \
    && cd openstreetmap-carto \
    && rm -rf .git \
    && npm install -g carto@0.18.2 \
#&& cp /project.mml . \
    && carto project.mml > mapnik.xml \
    && scripts/get-shapefiles.py

COPY renderd.conf /usr/local/etc/renderd.conf

RUN sed -i 's/renderaccount/renderer/g' /usr/local/etc/renderd.conf \
    && sed -i 's/\/truetype//g' /usr/local/etc/renderd.conf \
    && sed -i 's/hot/tile/g' /usr/local/etc/renderd.conf

# Configure Apache
RUN mkdir /var/lib/mod_tile \
 	&& mkdir /var/run/renderd \
 	&& echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
 	&& echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
 	&& a2enconf mod_tile && a2enconf mod_headers \
 	&& mkdir -p /var/run/apache2

COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY leaflet-demo.html /var/www/html/index.html
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
	&& ln -sf /dev/stderr /var/log/apache2/error.log

COPY httpd-foreground /usr/local/bin/
RUN chmod 0700 /usr/local/bin/httpd-foreground

CMD ["httpd-foreground"]
