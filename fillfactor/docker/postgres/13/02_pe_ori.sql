\c ori13

CREATE TABLE projects (
    folder_id       integer NOT NULL,
    user_id         integer NOT NULL,
    team_id         integer NOT NULL,
    activity_log_id integer NOT NULL,
    edited_at       timestamp without time zone NOT NULL,
    PRIMARY KEY (folder_id, user_id)
);

CREATE INDEX ON projects (team_id);