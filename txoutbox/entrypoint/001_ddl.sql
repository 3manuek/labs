
-- \c postgres
-- CREATE EXTENSION pg_cron;


-- \c conductor
-- CREATE SCHEMA partman;
-- CREATE EXTENSION pg_partman SCHEMA partman;

CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username text not null
);


CREATE TYPE state AS ENUM ('INCOMING','PROCESSING', 'DONE', 
                'ERRORED', 'CANCELED', 'ARCHIVED');

CREATE TABLE event_conductor
(
    id                  UUID,
    current_state       state NOT NULL, 
    user_id             UUID         NOT NULL,  
    created_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    started_at          TIMESTAMP WITHOUT TIME ZONE,
    archived_at         TIMESTAMP WITHOUT TIME ZONE, -- Set by trigger on state change
    event_id         UUID      NOT NULL, -- REFERENCES pipelines (id)
    phase               VARCHAR(128),
    error_code          VARCHAR(128),
    error_message       VARCHAR(512),
    PRIMARY KEY (current_state, id)
) PARTITION BY LIST (current_state);

CREATE INDEX ON event_conductor (archived_at);
-- CREATE INDEX on event_conductor (pipeline_version_id, archived_at) 
--     WHERE completed_at IS NULL AND current_state = 'COMPLETED'::state;


CREATE TABLE event_conductor_incoming
PARTITION OF event_conductor
FOR VALUES IN ('INCOMING')
WITH (FILLFACTOR=50);

-- We need to do the same with the indexes, as by default is 70.

CREATE TABLE event_conductor_processing 
PARTITION OF event_conductor
FOR VALUES IN ('PROCESSING')
WITH (FILLFACTOR=50);

CREATE TABLE event_conductor_done 
PARTITION OF event_conductor
FOR VALUES IN ('DONE')
WITH (FILLFACTOR=100);

CREATE TABLE event_conductor_canceled
PARTITION OF event_conductor
FOR VALUES IN ('CANCELED')
WITH (FILLFACTOR=100);

CREATE TABLE event_conductor_errored
PARTITION OF event_conductor
FOR VALUES IN ('ERRORED')
WITH (FILLFACTOR=100);

-- we truncate this partition in hourly basis
CREATE TABLE event_conductor_completed 
PARTITION OF event_conductor
FOR VALUES IN ('ARCHIVED')
WITH (FILLFACTOR=100);

--- Old strategy for using range partitioning
-- PARTITION BY RANGE (completed_at) ;

-- CREATE TABLE event_conductor_completed_2024 
-- PARTITION OF event_conductor_completed
-- FOR VALUES FROM ('2024-01-01') TO ('2024-12-31') 
-- WITH (FILLFACTOR=100);


---- Original Indexes
-- create index on event_conductor (completed_at, archived_at) where completed_at is not null and archived_at is null;
-- create index on event_conductor (completed_at, archived_at) where completed_at is null;
-- create index on event_conductor (completed_at, created_at) where completed_at is null;
-- create index on event_conductor (archived_at) where archived_at is not null;
-- create index on event_conductor (pipeline_version_id, completed_at) where completed_at is null;
-- create index on event_conductor (completed_at, archived_at) where completed_at is not null and archived_at is null;

CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_event_conductor_updated_at
    BEFORE UPDATE
    ON event_conductor
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

