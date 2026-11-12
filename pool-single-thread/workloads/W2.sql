-- W2: insert/update/select transaction (5 round-trips inside an explicit transaction).
-- Unlike TPC-B, it does not touch pgbench_branches/tellers: those hot rows would make
-- row-lock contention in Postgres the bottleneck instead of the pooler.
\set aid random(1, 100000 * :scale)
\set bid random(1, 1 * :scale)
\set tid random(1, 10 * :scale)
\set delta random(-5000, 5000)
BEGIN;
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
COMMIT;
