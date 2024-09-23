# OpenWrt Docker repository

[![GPL-2.0-only License][license-badge]][license-ref]
[![CI][ci-badge]][ci-ref]
[![Docker Hub][docker-hub-badge]][docker-hub-ref]

This repository was forked from [OpenWRT/Docker](https://github.com/openwrt/docker), and just do some localization support, such as mirrors, feeds, etc.

## Build Your Own

If you wan to create your own container you can use the `Dockerfile`. You can set the following build arguments:

* `TARGET` - the target to build for (e.g. `x86/64`)
* `DOWNLOAD_FILE` - the file to download (e.g. `imagebuilder-.*x86_64.tar.xz`)
* `FILE_HOST` - the host to download the ImageBuilder/SDK/rootfs from (e.g. `downloads.openwrt.org`)
* `VERSION_PATH` - the path to the ImageBuilder/SDK/rootfs (e.g. `snapshots` or `releases/21.02.3`)
* `MIRROR` - the host to download the packages of basic image from (e.g. `downloads.debian.org`)

### Example ImageBuilder

> If you plan to use your own server please add your own GPG key to the
> `./keys/` folder.

```shell
docker build \
    --build-arg TARGET=x86/64 \
    --build-arg DOWNLOAD_FILE="imagebuilder-.*x86_64.tar.xz" \
    --build-arg FILE_HOST=downloads.openwrt.org \
    --build-arg VERSION_PATH=releases/23.05.4 \
    --build-arg MIRROR=deb.debian.org \
    -t openwrt/x86-64-23.05:4 .
```

[ci-badge]: https://github.com/openwrt/docker/actions/workflows/containers.yml/badge.svg
[ci-ref]: https://github.com/openwrt/docker/actions/workflows/containers.yml
[docker-hub-badge]: https://img.shields.io/badge/docker--hub-openwrt-blue.svg?style=flat-square
[docker-hub-ref]: https://hub.docker.com/u/openwrt
[license-badge]: https://img.shields.io/github/license/openwrt/docker.svg?style=flat-square
[license-ref]: LICENSE
