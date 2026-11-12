-- W1: short read-only transaction (single autocommit PK lookup, equivalent to `pgbench -S`).
-- Almost zero server time => measures pure pooler per-transaction overhead.
\set aid random(1, 100000 * :scale)
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
