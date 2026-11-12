#!/usr/bin/env bash
# Runs once, on an empty data directory (docker-entrypoint-initdb.d semantics).
# Builds the template database `bench_tpl`; every benchmark cell clones `bench` from it.
set -euo pipefail

SCALE="${SCALE:-10}"
ORDERS_PER_ACCOUNT="${ORDERS_PER_ACCOUNT:-0.5}"
PSQL=(psql -v ON_ERROR_STOP=1 --username postgres --no-psqlrc)
PSQL_BENCH=(psql -v ON_ERROR_STOP=1 --username bench --no-psqlrc)

echo ">> creating role/template (scale=${SCALE}, orders/account=${ORDERS_PER_ACCOUNT})"
"${PSQL[@]}" -d postgres <<-SQL
  CREATE ROLE bench LOGIN PASSWORD 'bench';
  CREATE DATABASE bench_tpl OWNER bench;
SQL

"${PSQL[@]}" -d bench_tpl <<-SQL
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
  CREATE EXTENSION IF NOT EXISTS pg_buffercache;
  GRANT pg_read_all_stats TO bench;
SQL

echo ">> pgbench -i -s ${SCALE}"
pgbench -i -s "${SCALE}" -I dtGvp -h /var/run/postgresql -U bench bench_tpl

echo ">> CRUD schema (orders / order_items)"
"${PSQL_BENCH[@]}" -d bench_tpl <<-SQL
  CREATE TABLE orders (
    order_id   bigserial PRIMARY KEY,
    aid        int         NOT NULL,
    status     text        NOT NULL,
    total      numeric(12,2) NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz
  );
  CREATE TABLE order_items (
    item_id  bigserial PRIMARY KEY,
    order_id bigint NOT NULL REFERENCES orders ON DELETE CASCADE,
    sku      int NOT NULL,
    qty      int NOT NULL,
    price    numeric(10,2) NOT NULL
  );

  INSERT INTO orders (aid, status, total, created_at)
  SELECT 1 + (random() * (100000 * ${SCALE} - 1))::int,
         (ARRAY['new','paid','shipped','cancelled'])[1 + (random() * 3)::int],
         round((random() * 500)::numeric, 2),
         now() - random() * interval '365 days'
  FROM generate_series(1, (100000 * ${SCALE} * ${ORDERS_PER_ACCOUNT})::bigint);

  INSERT INTO order_items (order_id, sku, qty, price)
  SELECT o.order_id, 1 + (random() * 9999)::int, 1 + (random() * 4)::int, round((random() * 100)::numeric, 2)
  FROM orders o, generate_series(1, 3);

  CREATE INDEX orders_aid_status_idx ON orders (aid, status);
  CREATE INDEX order_items_order_id_idx ON order_items (order_id);
  VACUUM (ANALYZE, FREEZE);

  -- marker used by `make seed` / healthcheck to detect a completed seed
  CREATE TABLE lab_seed (scale int, orders_per_account numeric, seeded_at timestamptz DEFAULT now());
  INSERT INTO lab_seed VALUES (${SCALE}, ${ORDERS_PER_ACCOUNT});
SQL

echo ">> freezing template and creating first bench copy"
"${PSQL[@]}" -d postgres <<-SQL
  ALTER DATABASE bench_tpl WITH IS_TEMPLATE true ALLOW_CONNECTIONS false;
  CREATE DATABASE bench TEMPLATE bench_tpl OWNER bench STRATEGY FILE_COPY;
SQL
echo ">> seed done"
