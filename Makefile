IMAGE_NAME=curl-quictls-deb

build:
	docker build -t $(IMAGE_NAME) .
	docker run --rm -it -v .:/dist --entrypoint=install $(IMAGE_NAME) /curl-quictls.deb /dist/curl-quitls_8.1.2+dep.1-1ppa1~ubuntu22.04_amd64.deb

.PHONY: build
