FROM php:8.1-fpm-alpine

MAINTAINER Yuan <kenshin912@gmail.com>

ENV TZ=Asia/Shanghai

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN set -eux; \
        sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories; \
        chmod +x /usr/local/bin/install-php-extensions; \
        install-php-extensions \
        amqp \
        apcu \
        bcmath \
        calendar \
        decimal \
        event \
        exif \
        gd \
        imagick \
        intl \
        memcached \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        redis \
        sockets \
        soap \
        swoole \
        tidy \
        timezonedb \
        uuid \
        zip; \
        #usermod -u 1000 www-data \
        #groupmod -g 1000 www-data \
        rm -rf /var/cache/apk/* \
        rm -f /usr/local/etc/php-fpm.d/www.conf

WORKDIR /usr/local/etc/

ENTRYPOINT ["docker-php-entrypoint"]

CMD ["php-fpm","-R"]

EXPOSE 9000