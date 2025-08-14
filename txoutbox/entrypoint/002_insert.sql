INSERT INTO users (user_id, username) VALUES
(gen_random_uuid(), 'user1'),
(gen_random_uuid(), 'user2'),
(gen_random_uuid(), 'user3'),
(gen_random_uuid(), 'user4'),
(gen_random_uuid(), 'user5');

-- Initial insert only over NOT_READY, we do updates and archiving afterwards
INSERT INTO event_conductor
SELECT
    gen_random_uuid(), --id
    'INCOMING'::state, --state
    (select user_id from users order by random() LIMIT 1 ), --user_id
    now(), --created_at
    now(), --updated_at
    now(), --started_at
    null, --completed_at
    gen_random_uuid(), -- pipeline_id
    FLOOR(1 + RANDOM() * 10)::smallint, --objects_count_down
    gen_random_uuid(), --pipeline_version_id
    now()+'1 second'::interval, --next_sync_at
    repeat('error',5), --error_mesage
    '{}'::jsonb --stat    
FROM generate_series(1,10000);


select tableoid::regclass, current_state, id, user_id, objects_count_down from event_conductor limit 10;

SELECT tableoid::regclass, count(id) FROM event_conductor GROUP BY tableoid::regclass;

SELECT i.i, pg_size_pretty(pg_total_relation_size(i.i::text)) FROM 
    (SELECT tablename FROM pg_tables WHERE tablename ~ 'event_conductor') i(i);

-- Lab
DO $updateToReady$
DECLARE
    i record;
    cdown smallint = 1; --just not 0 from the start
BEGIN
    WHILE cdown > 0  LOOP
        SELECT count(id) INTO cdown FROM event_conductor WHERE current_state = 'NOT_READY' and objects_count_down > 0;
        FOR i IN SELECT id, objects_count_down FROM event_conductor 
                    WHERE current_state = 'INCOMING'::state 
                    LIMIT 1000
        LOOP 
            IF i.objects_count_down > 0 THEN
                UPDATE event_conductor SET objects_count_down=objects_count_down-1 WHERE id = i.id;
            END IF;
            IF i.objects_count_down = 0 THEN
                UPDATE event_conductor SET current_state = 'READY'::state WHERE id = i.id;
            END IF;
        END LOOP;
        COMMIT AND CHAIN;
    END LOOP;
    
    -- RAISE NOTICE 'Count Down %', cdown;
    COMMIT; -- we commit and close chain
END
$updateToReady$;

SELECT tableoid::regclass, count(id) FROM event_conductor GROUP BY tableoid::regclass;
SELECT i.i, pg_size_pretty(pg_total_relation_size(i.i::text)) 
    FROM (SELECT tablename FROM pg_tables WHERE tablename ~ 'event_conductor') i(i);

