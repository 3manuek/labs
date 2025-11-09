-- BEGIN;
\set key random(1, 10000 * :scale)

-- Write: Insert a new user
SET SHARDING KEY TO ':key';

BEGIN;
INSERT INTO users (username, email) VALUES (
    :key,
    :key || '@example.com'
) ON CONFLICT (username) DO NOTHING;

SELECT * FROM users WHERE email = :key || '@example.com';
END;
-- Read: Select a user by email
-- \set user_email 'user' || :random_number || '@example.com'
-- SELECT * FROM users WHERE email = :user_email;

-- Write: Insert a new user
-- \set new_user_name 'User' || :random_number
-- \set new_user_email 'newuser' || :random_number || '@example.com'
-- INSERT INTO users (id, name, email) VALUES (:new_user_id, :new_user_name, :new_user_email);

\set newkey random(1, 10000 * :scale)

SET SHARDING KEY TO ':key';
BEGIN;
-- -- Write: Update a user's name
-- \set update_user_name random(1, 1000 * :scale)
-- UPDATE users SET username = :newkey WHERE username = :key;
DELETE FROM users WHERE username = :key;
END;
SET SHARDING KEY TO ':newkey';
BEGIN;
INSERT INTO users VALUES (:newkey, ':key' || '@changed.com')
ON CONFLICT (username) DO NOTHING;
-- Write: Delete a user by ID
-- DELETE FROM users WHERE id = :user_id;
END;