FROM python:3.9-buster AS builder

ARG VERSION=1.16.0

LABEL maintainer "Mark Lopez <m@silvenga.com>"
LABEL org.opencontainers.image.source https://github.com/silvenga-docker/electrumx

# https://github.com/spesmilo/electrumx/blob/master/contrib/Dockerfile
WORKDIR /usr/src/app

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
    librocksdb-dev libsnappy-dev libbz2-dev libz-dev liblz4-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv venv \
    && venv/bin/pip install --no-cache-dir e-x[rapidjson,rocksdb]==${VERSION}

FROM python:3.9-slim-buster

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
    librocksdb5.17 libsnappy1v5 libbz2-1.0 zlib1g liblz4-1 \
    && rm -rf /var/lib/apt/lists/*

ENV SERVICES="tcp://:50001"
ENV COIN=Bitcoin
ENV DB_DIRECTORY=/var/lib/electrumx
ENV DAEMON_URL="http://username:password@hostname:port/"
ENV ALLOW_ROOT=true
ENV DB_ENGINE=rocksdb
ENV MAX_SEND=10000000
ENV BANDWIDTH_UNIT_COST=50000
ENV CACHE_MB=2000

WORKDIR /usr/src/app
COPY --from=builder /usr/src/app .

VOLUME /var/lib/electrumx

RUN mkdir -p "$DB_DIRECTORY" && ulimit -n 1048576

CMD ["/usr/src/app/venv/bin/python", "/usr/src/app/venv/bin/electrumx_server"]
