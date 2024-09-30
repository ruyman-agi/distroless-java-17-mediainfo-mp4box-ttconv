FROM debian:stretch-slim AS builder
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list
RUN sed -i s/security.debian.org/archive.debian.org/g /etc/apt/sources.list
RUN sed -i s/stretch-updates/stretch/g /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
                       curl ca-certificates \
                       build-essential pkg-config \
                       zlib1g-dev 
WORKDIR /build
RUN \
  curl -L -o gpac.tar.gz \
       https://github.com/gpac/gpac/archive/refs/tags/v2.0.0.tar.gz \
  && tar xaf gpac.tar.gz \
  && cd gpac-2.0.0 \
  && ./configure --static-mp4box \
  && make
RUN \
  curl -o mediainfo.tar.xz \
       https://mediaarea.net/download/binary/mediainfo/21.03/MediaInfo_CLI_21.03_GNU_FromSource.tar.xz \
  && tar xaf mediainfo.tar.xz \
  && cd MediaInfo_CLI_GNU_FromSource \
  && ./CLI_Compile.sh
RUN \
  mkdir /dist \
  && mv MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo \
     /dist/mediainfo \
  && mv gpac-2.0.0/bin/gcc/MP4Box /dist/MP4Box


FROM python:3.12.6-slim-bookworm AS python-builder
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --pre ttconv


FROM registry.agilecontent.com/docker/distroless-java-17/main:latest
FROM gcr.io/distroless/java17 
ADD busybox.tar /bin/
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
COPY --from=builder /dist/MP4Box /dist/mediainfo /usr/bin/
COPY --from=python-builder /lib /lib
COPY --from=python-builder /lib64 /lib64
COPY --from=python-builder /usr/local/bin /usr/local/bin
COPY --from=python-builder /usr/local/lib /usr/local/lib
ENV PYTHONPATH="/usr/local/lib/python3.12/site-packages/ttconv:$PYTHONPATH"
RUN chown root:root -R /bin
