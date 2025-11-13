-- https://www.postgresql.org/docs/current/catalog-pg-subscription-rel.html
\c testdb

SELECT 
    srsubstate as code,
    CASE srsubstate
        WHEN 'i' THEN 'initialize'
        WHEN 'd' THEN 'data is being copied'
        WHEN 'f' THEN 'finished table copy'
        WHEN 's' THEN 'synchronized'
        WHEN 'r' THEN 'ready (normal replication)'
        ELSE 'unknown'
    END AS state_description,
    count(*) as count_states
FROM pg_subscription_rel 
WHERE srsubid = (SELECT oid FROM pg_subscription WHERE subname = 'all_sub')
GROUP BY srsubstate;
