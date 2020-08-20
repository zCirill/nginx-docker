FROM debian:stretch-20200803 AS builder

ENV NGINX_VERSION=1.18.0 \
    NGINX_BUILD_ASSETS_DIR=/var/lib/docker-nginx \
    NGINX_BUILD_ROOT_DIR=/var/lib/docker-nginx/rootfs

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gcc \
    make g++ pkg-config libpcre++-dev libssl-dev zlib1g-dev libxslt1-dev libgd-dev libgeoip-dev uuid-dev wget ca-certificates


ADD http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz ${NGINX_BUILD_ASSETS_DIR}/nginx-${NGINX_VERSION}.tar.gz

RUN mkdir -p $NGINX_BUILD_ASSETS_DIR/nginx $NGINX_BUILD_ROOT_DIR
RUN tar xf ${NGINX_BUILD_ASSETS_DIR}/nginx-${NGINX_VERSION}.tar.gz --strip=1 -C ${NGINX_BUILD_ASSETS_DIR}/nginx
RUN cd ${NGINX_BUILD_ASSETS_DIR}/nginx \
&& ./configure \
  --prefix=/usr/share/nginx \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --pid-path=/run/nginx.pid \
  --lock-path=/var/lock/nginx.lock \
  --with-threads \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_xslt_module \
  --with-http_image_filter_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_stub_status_module \
  --with-http_geoip_module \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --with-mail \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-pcre-jit \
  --with-cc-opt='-O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -D_FORTIFY_SOURCE=2' \
  --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' \
&& make -j$(nproc) && make DESTDIR=${NGINX_BUILD_ROOT_DIR} install

# install default configuration
COPY assets/build/ ${NGINX_BUILD_ASSETS_DIR}/
RUN mkdir -p ${NGINX_BUILD_ROOT_DIR}/etc/nginx/sites-enabled
RUN cp ${NGINX_BUILD_ASSETS_DIR}/config/nginx.conf ${NGINX_BUILD_ROOT_DIR}/etc/nginx/nginx.conf

COPY entrypoint.sh ${NGINX_BUILD_ROOT_DIR}/sbin/entrypoint.sh

RUN chmod 755 ${NGINX_BUILD_ROOT_DIR}/sbin/entrypoint.sh

FROM debian:stretch-20200803

ENV NGINX_USER=www-data \
    NGINX_SITECONF_DIR=/etc/nginx/sites-enabled \
    NGINX_LOG_DIR=/var/log/nginx \
    NGINX_TEMP_DIR=/var/lib/nginx

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      libssl1.1 libxslt1.1 libgd3 libgeoip1 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /var/lib/docker-nginx/rootfs /

EXPOSE 80/tcp 443/tcp 1935/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/sbin/nginx"]
