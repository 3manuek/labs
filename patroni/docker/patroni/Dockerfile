FROM postgres:17-alpine

RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-psycopg2 \
    py3-setuptools \
    py3-wheel \
    curl \
    gcc \
    python3-dev \
    musl-dev \
    libffi-dev \
    su-exec \
    jq \
    && pip3 install --no-cache-dir --break-system-packages patroni[etcd3] \
    && apk del gcc python3-dev musl-dev libffi-dev

RUN mkdir -p /var/run/postgresql && \
    chown postgres:postgres /var/run/postgresql && \
    mkdir -p /var/lib/postgresql/data && \
    chmod 700 /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5432 8008

ENTRYPOINT ["/entrypoint.sh"]
