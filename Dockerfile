FROM ubuntu:22.04

# Install dependencies RUN apt update \
RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y --no-install-recommends \
       libapache2-mod-tile \
       renderd \
       git \
       tar \
       bzip2 \
       apache2 \
       lua5.1 \
       mapnik-utils \
       python3-mapnik \
       python3-psycopg2 \
       python3-yaml \
       npm \
       gdal-bin \
       fonts-noto-cjk \
       fonts-noto-hinted \
       fonts-noto-unhinted \
       fonts-unifont \
       fonts-hanazono \
       osm2pgsql \
       net-tools

RUN git clone --single-branch --branch v5.6.2 https://github.com/gravitystorm/openstreetmap-carto.git \
    && cd openstreetmap-carto \
    && rm -rf .git \
    && npm install -g carto@1.2.0 \
    && carto project.mml > mapnik.xml

RUN mkdir /run/renderd/
COPY renderd.conf /etc/renderd.conf
 
## Configure Apache
#RUN mkdir /var/lib/mod_tile \
# 	&& mkdir /var/run/renderd \
# 	&& echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
# 	&& echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
# 	&& a2enconf mod_tile && a2enconf mod_headers \
# 	&& mkdir -p /var/run/apache2
 
#COPY apache.conf /etc/apache2/sites-available/000-default.conf
#RUN ln -sf /dev/stdout /var/log/apache2/access.log \
#	&& ln -sf /dev/stderr /var/log/apache2/error.log

COPY httpd-foreground /usr/local/bin/
RUN chmod 0700 /usr/local/bin/httpd-foreground
CMD ["httpd-foreground"]
