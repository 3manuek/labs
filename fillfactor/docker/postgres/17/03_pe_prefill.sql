-- We prefill so we emulate a current status in production,
-- cause it takes considerable time for insert each entry from users.

\c ori17

INSERT INTO projects ("folder_id","user_id","team_id","activity_log_id","edited_at") 
SELECT folder_id, user_id, team_id, 1, now() FROM users;

-- \c by_hash

-- INSERT INTO projects ("folder_id","user_id","team_id","activity_log_id","edited_at") 
-- SELECT folder_id, user_id, team_id, 1, now() FROM users;

\c onlyff17

INSERT INTO projects ("folder_id","user_id","team_id","activity_log_id","edited_at") 
SELECT folder_id, user_id, team_id, 1, now() FROM users;