FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y build-essential git autoconf libtool pkg-config \
                       zlib1g-dev libzstd-dev libbrotli-dev libidn2-dev libnghttp2-dev

# Build quictls
WORKDIR /src
ENV OPENSSL_DIRNAME=openssl-1.1.1u-quic
RUN git clone -b OpenSSL_1_1_1u+quic --depth 1 \
        https://github.com/quictls/openssl \
        $OPENSSL_DIRNAME
WORKDIR /src/$OPENSSL_DIRNAME
RUN ./config no-shared enable-tls1_3 \
    --prefix=/usr --openssldir=/usr/lib/ssl --libdir=lib/$(uname -m)-linux-gnu \
    no-idea no-mdc2 no-rc5 no-zlib no-ssl3 enable-unit-test no-ssl3-method enable-rfc3779 enable-cms
RUN make -j
RUN make install

# Build nghttp3
WORKDIR /src
RUN git clone --depth 1 -b v0.12.0 https://github.com/ngtcp2/nghttp3
WORKDIR /src/nghttp3
RUN autoreconf -fi
RUN ./configure --prefix=/usr --libdir=/usr/lib/$(uname -m)-linux-gnu --enable-lib-only --disable-shared
RUN make -j
RUN make install

# Build ngtcp2
WORKDIR /src
RUN git clone --depth 1 -b v0.15.0 https://github.com/ngtcp2/ngtcp2
WORKDIR /src/ngtcp2
RUN autoreconf -fi
RUN ./configure --prefix=/usr --libdir=/usr/lib/$(uname -m)-linux-gnu --with-libnghttp3 --with-openssl --enable-lib-only --disable-shared
RUN make -j
RUN make install

# Build curl
WORKDIR /src
RUN git clone --depth 1 -b curl-8_1_2 https://github.com/curl/curl
WORKDIR /src/curl
RUN autoreconf -fi
RUN PKG_CONFIG_PATH="$PWD/../nghttp3/lib:$PWD/../ngtcp2/lib:$PWD/../ngtcp2/crypto/openssl" ./configure --prefix=/usr --with-ssl=/usr --with-nghttp3=/usr --with-ngtcp2=/usr --disable-shared --enable-alt-svc --enable-versioned-symbols
RUN make -j V=1
RUN make install

ENTRYPOINT ["/usr/bin/curl"]
