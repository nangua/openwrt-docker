ARG BASE_IMAGE=ghcr.io/openwrt/buildbot/buildworker-v3.11.1:latest

FROM ghcr.io/openwrt/buildbot/buildworker-v3.11.1:latest

WORKDIR /build/

# resize partition
ARG KERNEL_PARTSIZE=512
ARG ROOTFS_PARTSIZE=1024

# use "sdk-.*.Linux-x86_64.tar.xz" to create the SDK
ARG DOWNLOAD_FILE="imagebuilder-.*x86_64.tar.xz"
ARG TARGET=x86/64
ARG FILE_HOST
ARG VERSION_PATH
ARG MIRROR

# if $VERSION is empty fallback to snapshots
ENV VERSION_PATH=${VERSION_PATH:-snapshots}
ENV DOWNLOAD_PATH=$VERSION_PATH/targets/$TARGET
ENV FILE_HOST=${FILE_HOST:-downloads.openwrt.org}
# parse for sed
ENV MIRROR=${FILE_HOST//\//\/}

RUN curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums" -fs -o sha256sums
RUN curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums.asc" -fs -o sha256sums.asc || true
RUN curl "https://$FILE_HOST/$DOWNLOAD_PATH/sha256sums.sig" -fs -o sha256sums.sig || true

ADD keys/*.asc keys/
RUN gpg --import keys/*.asc
RUN gpg --with-fingerprint --verify sha256sums.asc sha256sums

# determine archive name
RUN echo $(grep "$DOWNLOAD_FILE" sha256sums | cut -d "*" -f 2) >> ~/file_name

# download imagebuilder/sdk archive
RUN wget --quiet "https://$FILE_HOST/$DOWNLOAD_PATH/$(cat ~/file_name)"

# shrink checksum file to single desired file and verify downloaded archive
RUN grep "$(cat ~/file_name)" sha256sums > sha256sums_min
RUN cat sha256sums_min
RUN sha256sum -c sha256sums_min

# cleanup
RUN rm -rf sha256sums{,_min,.sig,.asc} keys/

RUN tar xf "$(cat ~/file_name)" --strip=1 --no-same-owner -C .
RUN rm -rf "$(cat ~/file_name)"

RUN set -o errexit -o nounset \
  # select specific mirror
  && sed -i "s/downloads.openwrt.org/$MIRROR/" repositories.conf \
  && sed -i '3s/$/\nsrc\/gz dlkids https:\/\/op.dllkids.xyz\/packages\/x86_64\n/' repositories.conf \
  && sed -i '3s/$/\nsrc\/gz kiddin9 https:\/\/dl.openwrt.ai\/latest\/packages\/x86_64\/kiddin9/' repositories.conf \
  # ingore signature check
  && sed -i 's/^option check_signature/#option check_signature/' repositories.conf \
  && sed -i "s/downloads.openwrt.org/$MIRROR/" .config \
  && sed -i 's/CONFIG_TARGET_PREINIT_IP="192.168.1.1"/CONFIG_TARGET_PREINIT_IP="10.0.0.1"/' .config \
  && sed -i 's/CONFIG_TARGET_PREINIT_BROADCAST="192.168.1.255"/CONFIG_TARGET_PREINIT_BROADCAST="10.0.0.255"/' .config \
  # resize partition
  && sed -i "s/CONFIG_TARGET_KERNEL_PARTSIZE=16/CONFIG_TARGET_KERNEL_PARTSIZE=$KERNEL_PARTSIZE/" .config \
  && sed -i "s/CONFIG_TARGET_ROOTFS_PARTSIZE=104/CONFIG_TARGET_ROOTFS_PARTSIZE=$ROOTFS_PARTSIZE/" .config

FROM $BASE_IMAGE

ARG USER=buildbot
ARG WORKDIR=/builder/
ARG CMD="/bin/bash"
# select specific mirror
ARG MIRROR=deb.debian.org

# keep all up-to-date
RUN set -o errexit -o nounset \
  && sed -i -e "s/deb.debian.org/$MIRROR/g" -e "s/security.debian.org/$MIRROR/g" /etc/apt/sources.list \
  && apt-get update \
  && apt-get upgrade -y --assume-yes \
  && apt-get install -y --assume-yes vim \
  && apt-get clean 

USER $USER
WORKDIR $WORKDIR

COPY --from=0 --chown=$USER:$USER /build/ ./

ENTRYPOINT [ ]

# required to have CMD as ENV to be executed
ENV CMD_ENV=${CMD}
CMD ["${CMD_ENV}"]
