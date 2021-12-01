FROM ubuntu:20.04

# Install dependencies RUN apt update \
RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y --no-install-recommends \
       git \
       python \
       python-dev \
       libxml2 \
       libxml2-dev \
       zlib1g-dev \
       clang \
       make \
       pkg-config \
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
       libgdal-dev \
       gdal-bin \
       libgeos++-dev \
       libgeos-dev \
       libmapnik-dev \
       mapnik-utils \
       python3-mapnik \
       wget 

# Build mod_tile
RUN git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git \
	&& cd mod_tile \
	&& ./autogen.sh \
	&& ./configure \
	&& make -j $(nproc) \
	&& make install \
	&& make install-mod_tile \
	&& ldconfig


RUN ["/bin/bash", "-c", "set -o pipefail \
    && wget --quiet -O - https://deb.nodesource.com/setup_10.x | bash - \
    && apt update \
    && apt install -y nodejs"]

RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git \
    && git -C openstreetmap-carto checkout v5.4.0 \
    && cd openstreetmap-carto \
    && rm -rf .git \
    && npm install -g carto@1.2.0 \
    && carto project.mml > mapnik.xml

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
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
	&& ln -sf /dev/stderr /var/log/apache2/error.log

COPY httpd-foreground /usr/local/bin/
RUN chmod 0700 /usr/local/bin/httpd-foreground

RUN apt remove -y \
       git \
       gcc-6 \
       g++-6 \
       python-dev \
       libxml2-dev \
       zlib1g-dev \
       clang \
       make \
       pkg-config \
       ca-certificates \
       libboost-all-dev \
       libharfbuzz-dev \ 
       apache2-dev \
       autoconf \
       automake \
       libtool \
       build-essential \
       libcairo2-dev \
       python-cairo-dev \
       libcairomm-1.0-dev \
       libexpat1-dev \
       libfreetype6-dev \
       libpixman-1-dev \
       libjpeg-dev \
       libpng-dev \
       libproj-dev \
       libtiff-dev \
       libgdal-dev \
       libgeos++-dev \
       libgeos-dev \
       libmapnik-dev \
       python3-mapnik \
       wget \
       && apt autoremove -y

CMD ["httpd-foreground"]
