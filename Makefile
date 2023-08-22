IMAGE_NAME      = curl-quictls-deb
DEB_VERSION     = 8.2.1+quictls1.1.1v+dep.1-1hn1ubuntu22.04
CURL_GIT_TAG    = curl-8_2_1
QUICTLS_GIT_TAG = OpenSSL_1_1_1v+quic
# See https://curl.se/docs/http3.html for nghttp3 and ngtcp2 versions
NGHTTP3_GIT_TAG = v0.14.0
NGTCP2_GIT_TAG  = v0.18.0
NO_CACHE ?= --no-cache

build:
	docker build \
		$(NO_CACHE) --progress=plain \
		--build-arg QUICTLS_GIT_TAG=$(QUICTLS_GIT_TAG) \
		--build-arg NGHTTP3_GIT_TAG=$(NGHTTP3_GIT_TAG) \
		--build-arg NGTCP2_GIT_TAG=$(NGTCP2_GIT_TAG) \
		--build-arg CURL_GIT_TAG=$(CURL_GIT_TAG) \
		--build-arg DEB_VERSION=$(DEB_VERSION) \
		-t $(IMAGE_NAME) . 2>&1 | tee curl-quictls_$(DEB_VERSION)_amd64.build.log
	zstd --rm --force -19 curl-quictls_$(DEB_VERSION)_amd64.build.log
	docker run --rm -it -v .:/dist --entrypoint=install $(IMAGE_NAME) /curl-quictls.deb /dist/curl-quictls_$(DEB_VERSION)_amd64.deb

.PHONY: build
