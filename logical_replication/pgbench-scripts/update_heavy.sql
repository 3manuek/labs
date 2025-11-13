-- Update-heavy workload for demo_table
-- This script focuses on UPDATE operations

\set rand_id random(1, 10000)
\set rand_name random(1, 100000)
\set operation random(1, 100)

-- 80% UPDATE operations
\if :operation <= 80
    UPDATE demo_table SET name = 'Updated_' || :rand_name, created_at = NOW() WHERE id = :rand_id;
\else
    -- 20% SELECT operations to verify updates
    SELECT id, name, created_at FROM demo_table WHERE id = :rand_id;
\endif
