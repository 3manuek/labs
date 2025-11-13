-- Read-heavy workload for demo_table
-- This script focuses on SELECT operations with various patterns

\set rand_id random(1, 10000)
\set rand_limit random(10, 100)
\set operation random(1, 100)

-- Different types of read operations
\if :operation <= 40
    -- 40% Single row lookup by ID
    SELECT * FROM demo_table WHERE id = :rand_id;
\elif :operation <= 70
    -- 30% Range query with LIMIT
    SELECT * FROM demo_table ORDER BY created_at DESC LIMIT :rand_limit;
\elif :operation <= 85
    -- 15% COUNT operations
    SELECT COUNT(*) FROM demo_table;
\elif :operation <= 95
    -- 10% Pattern matching
    SELECT * FROM demo_table WHERE name LIKE 'User_%' LIMIT :rand_limit;
\else
    -- 5% Aggregate queries
    SELECT MIN(created_at), MAX(created_at), COUNT(*) FROM demo_table;
\endif
