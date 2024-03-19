FROM php:7.4-fpm-alpine

MAINTAINER Yuan <kenshin912@gmail.com>

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_NO_INTERACTION=1
ENV COMPOSER_HOME=/tmp/composer

RUN set -xe \
        && sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories \
        && apk --no-cache add tzdata \
        && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && apk del tzdata \
        && apk add --no-cache --virtual .build-dep $PHPIZE_DEPS curl-dev libtool libjpeg-turbo-dev libpng-dev libzip-dev libmcrypt-dev freetype-dev imagemagick-dev icu-dev \
        && apk add --no-cache shadow imagemagick \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j "$(nproc)" bcmath gd zip pdo pdo_mysql mysqli pcntl sockets \
        && pecl install imagick redis \
        && docker-php-ext-enable imagick redis \
        && curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
        && chmod +x /usr/bin/composer \
        && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
        && usermod -u 1000 www-data \
        && groupmod -g 1000 www-data \
        && apk del .build-dep shadow \
        && rm -rf /var/cache/apk/* \
        && rm -f /usr/local/etc/php-fpm.d/www.conf 

WORKDIR /usr/local/etc/

ENTRYPOINT ["docker-php-entrypoint"]

CMD ["php-fpm","-R"]

EXPOSE 9000
