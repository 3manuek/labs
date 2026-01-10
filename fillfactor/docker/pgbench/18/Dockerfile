FROM ubuntu:latest

# Set environment variables with defaults
ARG HOST=postgres18
ARG POSTGRES_USER=postgres
ARG POSTGRES_PASSWORD=postgres
ARG POSTGRES_DB=testdb
ARG PGPASSWORD=postgres
ARG SCRIPT=/upserts.sql
ARG CLIENTS=16
ARG JOBS=2
ARG TIME=300
ARG PROGRESS=10

# Add PostgreSQL official repository and install pgbench
RUN LANG=us apt-get update && apt-get install -y wget gnupg lsb-release && \
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && apt-get install -y postgresql-client-18 postgresql-common postgresql-contrib && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Find the installed PostgreSQL version and set the path
RUN export PG_VERSION=$(pg_config --version | cut -d ' ' -f 2 | cut -d '.' -f 1) && \
    echo "export PATH=/usr/lib/postgresql/$PG_VERSION/bin:\$PATH" >> /etc/profile && \
    ln -s /usr/lib/postgresql/$PG_VERSION/bin/pgbench /usr/local/bin/pgbench

# Create postgres user
# RUN useradd -m -d /home/postgres -s /bin/bash postgres

# Switch to postgres user and set the home directory
USER postgres
WORKDIR /home/postgres


RUN export PATH="$PATH:/usr/lib/postgresql/$PG_VERSION/bin"
# Set entrypoint to pgbench
ENTRYPOINT ["sh", "-c", "\
    pgbench \
    -h ${HOST} \
    -c ${CLIENTS} \
    -U ${POSTGRES_USER} \
    -j ${JOBS} \
    -f ${SCRIPT} \
    -T ${TIME} \
    -P ${PROGRESS} \
    --progress-timestamp \
    ${POSTGRES_DB}"]