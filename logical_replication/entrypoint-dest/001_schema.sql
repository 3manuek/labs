CREATE TABLE demo_table (
    id BIGSERIAL PRIMARY KEY,
    name text,
    created_at TIMESTAMP DEFAULT NOW()
);

create table testtable (i bigserial, sometxt text);

