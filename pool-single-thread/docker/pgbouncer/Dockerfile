# PgBouncer built from the official release tarball (Alpine packages lag behind upstream).
# Steps are split so a failure points at the exact stage:
#   docker compose build --progress=plain pgbouncer
FROM alpine:3.22 AS build
ARG PGBOUNCER_VERSION=1.26.0
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache build-base pkgconf libevent-dev openssl-dev c-ares-dev curl ca-certificates tar

WORKDIR /src
# 1. download: pgbouncer.org first, GitHub release asset as fallback
RUN V="${PGBOUNCER_VERSION}"; T="pgbouncer_$(echo "$V" | tr . _)"; \
    for url in \
      "https://www.pgbouncer.org/downloads/files/${V}/pgbouncer-${V}.tar.gz" \
      "https://github.com/pgbouncer/pgbouncer/releases/download/${T}/pgbouncer-${V}.tar.gz"; do \
      echo "trying $url"; \
      if curl -fsSL --retry 3 -o /tmp/pgbouncer.tar.gz "$url"; then break; fi; \
      rm -f /tmp/pgbouncer.tar.gz; \
    done; \
    test -s /tmp/pgbouncer.tar.gz || { echo "download failed for ${V}" >&2; exit 1; }

# 2. extract (GNU tar; busybox tar lacks some options)
RUN tar -xzf /tmp/pgbouncer.tar.gz --strip-components=1 && ls

# 3. configure (config.log is printed on failure)
RUN ./configure --prefix=/usr/local --with-cares || { cat config.log; exit 1; }

# 4. build + install (only the binary: no pandoc needed for man pages)
RUN make -j"$(nproc)" pgbouncer && install -m 0755 pgbouncer /usr/local/bin/pgbouncer \
 && /usr/local/bin/pgbouncer --version

FROM alpine:3.22
RUN apk add --no-cache libevent openssl c-ares \
 && adduser -D -H -s /sbin/nologin pgbouncer
COPY --from=build /usr/local/bin/pgbouncer /usr/local/bin/pgbouncer
USER pgbouncer
EXPOSE 6432
ENTRYPOINT ["/usr/local/bin/pgbouncer"]
CMD ["/etc/pgbouncer/pgbouncer.ini"]
