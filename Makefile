IMAGE_NAME      = curl-quictls-deb
DEB_VERSION     = 8.1.2+dep.1-1ppa1ubuntu22.04
CURL_GIT_TAG    = curl-8_1_2
QUICTLS_GIT_TAG = OpenSSL_1_1_1u+quic
NGHTTP3_GIT_TAG = v0.12.0
NGTCP2_GIT_TAG  = v0.15.0

build:
	docker build \
		--build-arg QUICTLS_GIT_TAG=$(QUICTLS_GIT_TAG) \
		--build-arg NGHTTP3_GIT_TAG=$(NGHTTP3_GIT_TAG) \
		--build-arg NGTCP2_GIT_TAG=$(NGTCP2_GIT_TAG) \
		--build-arg CURL_GIT_TAG=$(CURL_GIT_TAG) \
		--build-arg DEB_VERSION=$(DEB_VERSION) \
		-t $(IMAGE_NAME) .
	docker run --rm -it -v .:/dist --entrypoint=install $(IMAGE_NAME) /curl-quictls.deb /dist/curl-quitls_$(DEB_VERSION)_amd64.deb

.PHONY: build
