.PHONY: help up start stop down clean logs status setup test-insert verify

help:
	@echo "Available commands:"
	@echo "  make up           - Start all services"
	@echo "  make setup        - Configure Debezium and ClickHouse connectors"
	@echo "  make stop         - Stop all services"
	@echo "  make down         - Stop and remove containers"
	@echo "  make clean        - Remove everything including volumes"
	@echo "  make logs         - View logs from all services"
	@echo "  make status       - Check connector status"
	@echo "  make verify       - Verify data in ClickHouse"
	@echo "  make test-insert  - Insert test data into Postgres"

up:
	docker compose up -d
	@echo "Services starting... Wait 30 seconds before running 'make setup'"

start: up

setup:
	./setup-connectors.sh

stop:
	docker compose stop

down:
	docker compose down

clean:
	docker compose down -v
	@echo "All containers, networks, and volumes removed"

logs:
	docker compose logs -f

status:
	@echo "=== Debezium Postgres Source Connector ==="
	@curl -s http://localhost:8083/connectors/postgres-source/status | jq '.' 2>/dev/null || echo "Connector not found"
	@echo "\n=== Kafka-ClickHouse Consumer Status ==="
	@docker ps --filter name=kafka-clickhouse-consumer --format "table {{.Names}}\t{{.Status}}"

verify:
	docker exec -it clickhouse clickhouse-client --query "SELECT * FROM default.users ORDER BY id"

test-insert:
	docker exec -it postgres psql -U postgres -d testdb -c \
		"INSERT INTO users (name, email, age) VALUES ('Test User', 'test-$(shell date +%s)@example.com', 40);"
	@echo "Inserted test user. Run 'make verify' to check ClickHouse"
