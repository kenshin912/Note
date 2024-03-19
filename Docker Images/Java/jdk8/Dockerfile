FROM frolvlad/alpine-glibc:latest

LABEL MAINTAINER Cathryn <cathryn.crystal@gmail.com>

ADD jre.tar.gz /usr/local/
ADD fonts.tar.gz /usr/share/fonts/

COPY Shanghai /etc/localtime

ENV JAVA_HOME /usr/local/jre
ENV PATH ${PATH}:${JAVA_HOME}/bin
ENV LANG=en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN set -ex && \
    apk -U upgrade && \
    apk add --update tini graphicsmagick imagemagick && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.34-r0/glibc-i18n-2.34-r0.apk && \
    apk add glibc-i18n-2.34-r0.apk && \
    rm -rf *.apk && \
    rm -rf /var/cache/apk/* && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    echo "export LANG=en_US.UTF-8"

WORKDIR /home


