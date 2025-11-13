-- Insert-heavy workload for demo_table
-- This script focuses on INSERT operations with occasional reads

\set rand_name random(1, 100000)
\set operation random(1, 100)

-- 90% INSERT operations
\if :operation <= 90
    INSERT INTO demo_table (name) VALUES ('User_' || :rand_name);
\else
    -- 10% SELECT operations to verify inserts
    SELECT COUNT(*) FROM demo_table;
\endif
