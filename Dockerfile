# syntax=docker/dockerfile:1

ARG FLARUM_VERSION=v2.0.0-rc.1
# NOTE: FLARUM_PROJECT_VERSION exists separately from FLARUM_VERSION because the composer project was not updated for rc.1. As such, we have to use beta.8 as well, thus the additional variable. Presumably in the future there will be a stable release with matching versions and this variable can go away.
ARG FLARUM_PROJECT_VERSION=v2.0.0-beta.8
ARG ALPINE_VERSION=3.22

FROM tianon/gosu:latest AS gosu

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3
COPY --from=gosu /gosu /usr/local/bin/
RUN apk --update --no-cache add \
    bash \
    curl \
    libgd \
    mysql-client \
    mariadb-connector-c \
    nginx \
    php84 \
    php84-cli \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-fpm \
    php84-gd \
    php84-gmp \
    php84-iconv \
    php84-intl \
    php84-json \
    php84-mbstring \
    php84-mysqli \
    php84-opcache \
    php84-openssl \
    php84-pdo \
    php84-pdo_mysql \
    php84-pecl-uuid \
    php84-phar \
    php84-session \
    php84-simplexml \
    php84-sodium \
    php84-tokenizer \
    php84-xml \
    php84-xmlwriter \
    php84-zip \
    php84-zlib \
    shadow \
    tar \
    tzdata \
  && rm -rf /tmp/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"\
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG FLARUM_VERSION
ARG FLARUM_PROJECT_VERSION

RUN ln -s /usr/bin/php84 /usr/bin/php
RUN mkdir -p /opt/flarum \
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && COMPOSER_CACHE_DIR="/tmp" composer create-project flarum/flarum:${FLARUM_PROJECT_VERSION} /opt/flarum --no-install \
  && COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum -W flarum/core:${FLARUM_VERSION} \
  && COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum fof/polls:"*" \
  && COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum fof/reactions:"*" \
  && COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum michaelbelgium/mybb-to-flarum \
  && composer clear-cache \
  && addgroup -g ${PGID} flarum \
  && adduser -D -h /opt/flarum -u ${PUID} -G flarum -s /bin/sh -D flarum \
  && chown -R flarum:flarum /opt/flarum \
  && rm -rf /root/.composer /tmp/*

COPY rootfs /

EXPOSE 8000
WORKDIR /opt/flarum
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
