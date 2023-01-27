# Fetch stage #################################################################
FROM alpine:3.12 AS fetchstage

ADD . /ctbtemp/cesium-terrain-builder-mbtiles

# Build stage #################################################################
FROM alpine:3.12 AS buildstage
COPY --from=fetchstage /ctbtemp /ctbtemp

ARG gdal_version='3.1.4-r4'
ENV GDAL_VERSION=${gdal_version}

# Setup build deps
RUN set -ex && \
  apk update && \
  apk add --no-cache --virtual .build-deps \
    make cmake libxml2-dev g++ gdal-dev sqlite-dev

# Build & install cesium terrain builder
RUN set -x && \
  cd /ctbtemp/cesium-terrain-builder-mbtiles && \
  mkdir build && cd build && cmake .. && make install .

# Cleanup
RUN  set -x && \
  apk del .build-deps && \
  rm -rf /tmp/* && \
  rm -rf /ctbtemp

# Runtime stage #########################################################################
FROM alpine:3.12 AS runtimestage
COPY --from=buildstage /usr/local/include/ctb /usr/local/include/ctb
COPY --from=buildstage /usr/local/lib/libctb.so /usr/local/lib/libctb.so
COPY --from=buildstage /usr/local/bin/ctb-* /usr/local/bin/

ARG gdal_version='3.1.4-r0'
ENV GDAL_VERSION=${gdal_version}

WORKDIR /data

# Setup runtime deps
RUN set -ex && \
  apk update && \
  apk add --no-cache --virtual .rundeps \
  bash gdal=$GDAL_VERSION gdal-tools=$GDAL_VERSION && \
  echo 'shopt -s globstar' >> ~/.bashrc && \
  echo 'alias ..="cd .."' >> ~/.bashrc && \
  echo 'alias l="ls -CF --group-directories-first --color=auto"' >> ~/.bashrc && \
  echo 'alias ll="ls -lFh --group-directories-first --color=auto"' >> ~/.bashrc && \
  echo 'alias lla="ls -laFh --group-directories-first  --color=auto"' >> ~/.bashrc && \
  rm -rf /tmp/*

CMD ["bash"]


