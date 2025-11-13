-- Mixed workload script for demo_table
-- This script simulates a realistic mix of operations:
-- 50% reads, 30% inserts, 15% updates, 5% deletes

\set rand_id random(1, 10000)
\set rand_name random(1, 1000)
\set operation random(1, 100)

-- 50% SELECT operations (1-50)
\if :operation <= 50
    SELECT * FROM demo_table WHERE id = :rand_id;
\elif :operation <= 80
    -- 30% INSERT operations (51-80)
    INSERT INTO demo_table (name) VALUES ('User_' || :rand_name);
\elif :operation <= 95
    -- 15% UPDATE operations (81-95)
    UPDATE demo_table SET name = 'Updated_' || :rand_name, created_at = NOW() WHERE id = :rand_id;
\else
    -- 5% DELETE operations (96-100)
    DELETE FROM demo_table WHERE id = :rand_id;
\endif
