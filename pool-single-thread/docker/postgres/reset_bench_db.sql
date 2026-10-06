-- Executed before every benchmark cell (idempotency): fresh copy of the template + clean stats.
-- WITH (FORCE) terminates pooler/exporter connections to `bench`; poolers are restarted right after.
\set ON_ERROR_STOP 1
DROP DATABASE IF EXISTS bench WITH (FORCE);
CREATE DATABASE bench TEMPLATE bench_tpl OWNER bench STRATEGY FILE_COPY;
CHECKPOINT;
SELECT pg_stat_reset_shared('io');
SELECT pg_stat_reset_shared('wal');
\c bench
SELECT pg_stat_statements_reset();
-- prewarm the hot relations so the first seconds of the cell don't hit disk
SELECT count(*) FROM pgbench_accounts;
SELECT count(*) FROM orders;
SELECT count(*) FROM order_items;
