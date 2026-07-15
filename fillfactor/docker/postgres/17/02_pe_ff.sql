\c onlyff17

CREATE TABLE projects (
    folder_id       integer NOT NULL,
    user_id         integer NOT NULL,
    team_id         integer NOT NULL,
    activity_log_id integer NOT NULL,
    edited_at       timestamp without time zone NOT NULL,
    PRIMARY KEY (folder_id, user_id)
) WITH (FILLFACTOR=50);

-- ALTER INDEX projects_pkey SET (FILLFACTOR=50);

CREATE INDEX ON projects (team_id); -- WITH (FILLFACTOR=50);