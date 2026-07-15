#!/bin/bash

echo "Dumping"
pg_dump -U postgres testdb -c > /tmp/users.sql

echo "Restoring ori"
psql -U postgres -f /tmp/users.sql ori13
# echo "Restoring by_hash"
# psql -U postgres -f /tmp/users.sql by_hash
echo "Restoring onlyff"
psql -U postgres -f /tmp/users.sql onlyff13

