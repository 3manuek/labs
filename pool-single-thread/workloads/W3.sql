-- W3: full CRUD transaction with relatively slow statements.
-- Backend connections stay busy for a few ms per transaction, so with more clients than
-- POOL_SIZE the pooler has to queue clients => tests queueing/scheduling, not just forwarding.
--   :span      accounts covered by the range aggregate (bigger = slower read), default 2000
--   :sleep_ms  extra server-side time per transaction (pg_sleep), default 2
\set aid random(1, 100000 * :scale)
\set sku random(1, 10000)
\set qty random(1, 5)
BEGIN;
-- Create
INSERT INTO orders (aid, status) VALUES (:aid, 'new') RETURNING order_id \gset
INSERT INTO order_items (order_id, sku, qty, price) VALUES (:order_id, :sku, :qty, 9.99), (:order_id, :sku + 1, 1, 19.99);
UPDATE orders SET total = (SELECT sum(qty * price) FROM order_items WHERE order_id = :order_id) WHERE order_id = :order_id;
-- Read (range aggregate: the "slow" statement)
SELECT o.status, count(*), sum(o.total), avg(i.qty)
  FROM orders o JOIN order_items i USING (order_id)
 WHERE o.aid BETWEEN :aid AND :aid + :span
 GROUP BY o.status;
-- Update
UPDATE orders SET status = 'paid', updated_at = now()
 WHERE order_id = (SELECT order_id FROM orders WHERE aid BETWEEN :aid AND :aid + :span AND status = 'new' LIMIT 1);
-- Delete
DELETE FROM orders
 WHERE order_id = (SELECT order_id FROM orders WHERE aid BETWEEN :aid AND :aid + :span AND status = 'cancelled' LIMIT 1);
SELECT pg_sleep(:sleep_ms / 1000.0);
COMMIT;
