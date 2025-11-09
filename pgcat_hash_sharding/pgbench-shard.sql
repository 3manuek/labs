\set key random(1, 10000 * :scale)

SET SHARDING KEY TO ':key';

BEGIN;
INSERT INTO users (username, email) VALUES (
    :key,
    :key || '@example.com'
) ON CONFLICT (username) DO NOTHING;

SELECT username FROM users WHERE email = :key || '@example.com';
END;
