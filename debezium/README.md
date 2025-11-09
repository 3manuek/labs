# Debezium CDC Lab: PostgreSQL → ClickHouse

Simple CDC pipeline using Debezium to capture changes from PostgreSQL and stream them to ClickHouse.

## Architecture

```
PostgreSQL 18 → Debezium → Kafka → Python Consumer → ClickHouse
```

**Components:**
- PostgreSQL 18 with logical replication (WAL)
- Debezium Connect with PostgreSQL connector
- Apache Kafka with ZooKeeper
- Python consumer (kafka-python + clickhouse-driver)
- ClickHouse with MergeTree engine

📊 **[See detailed architecture diagrams in CHART.md](CHART.md)**

## Quick Start

**Using Makefile (recommended):**
```bash
make up          # Start all services
sleep 30         # Wait for services to initialize
make setup       # Configure connectors
make verify      # Check data in ClickHouse
```

**Manual commands:**
```bash
docker compose up -d
sleep 30
./setup-connectors.sh
docker exec -it clickhouse clickhouse-client --query "SELECT * FROM default.users"
```

## Makefile Commands

```bash
make help         # Show all available commands
make up           # Start all services
make setup        # Configure Debezium and ClickHouse connectors
make stop         # Stop services
make down         # Stop and remove containers
make clean        # Remove everything including volumes
make logs         # View logs
make status       # Check connector status
make verify       # Verify data in ClickHouse
make test-insert  # Insert test data into Postgres
```

## Testing CDC

Insert new data into PostgreSQL:
```bash
make test-insert
```

Or manually:
```bash
docker exec -it postgres psql -U postgres -d testdb -c \
  "INSERT INTO users (name, email, age) VALUES ('Test User', 'test@example.com', 40);"
```

Check ClickHouse for the new record:
```bash
make verify
```

## Access Points

- PostgreSQL: `localhost:5432` (user: postgres, pass: postgres)
- Kafka: `localhost:9092`
- Debezium API: `http://localhost:8083`
- ClickHouse HTTP: `http://localhost:8123`
- ClickHouse Native: `localhost:9000`

## Monitoring

Check connector status:
```bash
curl http://localhost:8083/connectors/postgres-source/status
curl http://localhost:8084/connectors/clickhouse-sink/status
```

View Kafka topics:
```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:29092
```

## Cleanup

```bash
make clean
```
