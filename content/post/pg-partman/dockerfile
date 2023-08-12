FROM postgres:15-alpine

ENV PG_PARTMAN_VERSION v4.7.3
ENV PG_CRON_VERSION v1.5.2

RUN set -ex \
    # Install build deps
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        clang15 \
        llvm15 \
        libtool \
        libxml2-dev \
        make \
    # Install pg_partman
    && wget -O pg_partman.tar.gz "https://github.com/pgpartman/pg_partman/archive/$PG_PARTMAN_VERSION.tar.gz" \
    && mkdir -p /usr/src/pg_partman \
    && tar \
        --extract \
        --file pg_partman.tar.gz \
        --directory /usr/src/pg_partman \
        --strip-components 1 \
    && rm pg_partman.tar.gz \
    && cd /usr/src/pg_partman \
    && make \
    && make install \
    && rm -rf /usr/src/pg_partman \
    && cd / \
    # Install pg_cron
    && wget -O pg_cron.tar.gz "https://github.com/citusdata/pg_cron/archive/$PG_CRON_VERSION.tar.gz" \
    && mkdir -p /usr/src/pg_cron \
    && tar \
        --extract \
        --file pg_cron.tar.gz \
        --directory /usr/src/pg_cron \
        --strip-components 1 \
    && rm pg_cron.tar.gz \
    && cd /usr/src/pg_cron \
    && make \
    && make install \
    && rm -rf /usr/src/pg_cron \
    && cd / \
    # Remove build deps
    && apk del .build-deps

# Custom entrypoint is needed to setup pg_cron
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]