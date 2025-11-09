#!/bin/bash

echo "Waiting for Debezium Connect to be ready..."
until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
    sleep 2
done
echo "Debezium Connect is ready!"

echo "Creating Debezium PostgreSQL source connector..."
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "postgres-source",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "testdb",
    "database.server.name": "dbserver1",
    "table.include.list": "public.users",
    "plugin.name": "pgoutput",
    "topic.prefix": "postgres"
  }
}'

echo -e "\n\nCreating ClickHouse table..."
docker exec clickhouse clickhouse-client --query "
CREATE TABLE IF NOT EXISTS default.users (
    id Int32,
    name String,
    email String,
    age Nullable(Int32),
    created_at Nullable(DateTime64(3))
) ENGINE = MergeTree()
ORDER BY id;
"

echo -e "\n\nSetup complete!"
echo "Data flows: Postgres -> Debezium -> Kafka -> Python Consumer -> ClickHouse"
echo ""
echo "Check status:"
echo "  curl http://localhost:8083/connectors/postgres-source/status"
echo "  docker logs kafka-clickhouse-consumer"
