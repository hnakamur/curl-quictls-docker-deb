FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y build-essential git autoconf libtool pkg-config \
                       zlib1g-dev libzstd-dev libbrotli-dev libidn2-dev libnghttp2-dev

# Build quictls
ARG QUICTLS_GIT_TAG
WORKDIR /src
RUN git clone -b $QUICTLS_GIT_TAG --depth 1 https://github.com/quictls/openssl
WORKDIR /src/openssl
RUN ./config no-shared enable-tls1_3 \
    --prefix=/usr --openssldir=/usr/lib/ssl --libdir=lib/$(uname -m)-linux-gnu \
    no-idea no-mdc2 no-rc5 no-zlib no-ssl3 enable-unit-test no-ssl3-method enable-rfc3779 enable-cms
RUN make -j
RUN make install

# Build nghttp3
ARG NGHTTP3_GIT_TAG
WORKDIR /src
RUN git clone --depth 1 -b $NGHTTP3_GIT_TAG https://github.com/ngtcp2/nghttp3
WORKDIR /src/nghttp3
RUN autoreconf -fi
RUN ./configure --prefix=/usr --libdir=/usr/lib/$(uname -m)-linux-gnu --enable-lib-only --disable-shared
RUN make -j
RUN make install

# Build ngtcp2
ARG NGTCP2_GIT_TAG
WORKDIR /src
RUN git clone --depth 1 -b $NGTCP2_GIT_TAG https://github.com/ngtcp2/ngtcp2
WORKDIR /src/ngtcp2
RUN autoreconf -fi
RUN ./configure --prefix=/usr --libdir=/usr/lib/$(uname -m)-linux-gnu --with-libnghttp3 --with-openssl --enable-lib-only --disable-shared
RUN make -j
RUN make install

# Build curl
ARG CURL_GIT_TAG
WORKDIR /src
RUN git clone --depth 1 -b $CURL_GIT_TAG https://github.com/curl/curl
WORKDIR /src/curl
RUN autoreconf -fi
RUN PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig" ./configure --prefix=/usr --with-ssl=/usr --with-nghttp3=/usr --with-ngtcp2=/usr --disable-shared --enable-alt-svc --enable-versioned-symbols
RUN make -j V=1
RUN make install

ARG DEB_VERSION
RUN apt-get install -y dpkg

RUN mkdir -p /curl-quictls/DEBIAN /curl-quictls/usr/bin
RUN install /usr/bin/curl /curl-quictls/usr/bin/curlq

COPY control.src /src/curl/debian/control
RUN dpkg-shlibdeps -Tsubstvars /curl-quictls/usr/bin/curlq

COPY control.tmpl /src/
RUN sed "s/@DEB_VERSION@/$DEB_VERSION/;s/@INSTALLED_SIZE@/$(ls -l /usr/bin/curl | awk '{print int($5 / 1024)}')/;s/@DEPENDS@/$(cut -d = -f 2- /src/curl/substvars)/" /src/control.tmpl > /curl-quictls/DEBIAN/control
WORKDIR /
RUN dpkg-deb --build curl-quictls

ENTRYPOINT ["/bin/bash"]
