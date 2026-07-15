\set user_id_rand random(1, 100000)

DO $$
DECLARE
    user_id_ran integer;
    folder_id_ran integer;
    team_id_ran integer;
    last_user_id integer;
BEGIN

    SELECT user_id, folder_id, team_id
        FROM users WHERE user_id = :user_id_rand
     INTO user_id_ran, folder_id_ran, team_id_ran;

    INSERT INTO projects ("folder_id","user_id","team_id","activity_log_id","edited_at") 
        VALUES (folder_id_ran,user_id_ran,team_id_ran,nextval('activity_log_id_seq'),now()) 
        ON CONFLICT (folder_id, user_id) 
        DO UPDATE SET "activity_log_id"=EXCLUDED."activity_log_id","edited_at"=EXCLUDED."edited_at"  
        ; --RETURNING "folder_id", "user_id";

END $$ LANGUAGE plpgsql;

