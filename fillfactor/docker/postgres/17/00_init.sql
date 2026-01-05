
CREATE TABLE users(
    user_id integer,
    folder_id integer NOT NULL,
    team_id integer NOT NULL,
    PRIMARY KEY (user_id, folder_id),
    UNIQUE (folder_id)
);

CREATE SEQUENCE users_user_id_seq;
CREATE SEQUENCE folders_folder_id_seq CACHE 100;
CREATE SEQUENCE activity_log_id_seq CACHE 100;
CREATE SEQUENCE teams_team_id_seq CACHE 100;

DO $$
DECLARE
    num_users integer := 100000; 
    user_idx integer;
    folder_cnt integer;
    folder_idx integer;
    user_id_ran integer;
BEGIN
    FOR user_idx IN 1..num_users LOOP
        SELECT nextval('users_user_id_seq') INTO user_id_ran;
        FOR folder_idx IN 1..(floor(random() * 200) + 1)::integer LOOP
            INSERT INTO users (user_id, folder_id, team_id) 
            VALUES (user_id_ran, nextval('folders_folder_id_seq'), nextval('teams_team_id_seq'));
        END LOOP;
    END LOOP;
    COMMIT;
END
$$;


CREATE DATABASE ori17;
\c ori17 
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- CREATE DATABASE by_hash;
-- \c by_hash
-- CREATE EXTENSION IF NOT EXISTS pgstattuple;
-- CREATE EXTENSION IF NOT EXISTS pg_buffercache;
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE DATABASE onlyff17;
\c onlyff17
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
