up:
	@docker compose up

upd:
	@docker compose up -d

up-back:
	@docker compose up -d prometheus grafana sql_exporter postgres_exporter13 postgres_exporter17 postgres_exporter18

up-13:
	@docker compose up -d postgres13  

up-18:
	@docker compose up -d postgres18

up-17:
	@docker compose up -d postgres17 

up-postgres: up-13 up-17 up-18

down-postgres: down-13 down-17 down-18

start-bench-13:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 started", "tags": ["v13"]}' || true
	@docker compose up -d pgbench_ori13 pgbench_onlyff13 

start-bench-17:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 started", "tags": ["v17"]}' || true
	@docker compose up -d pgbench_ori17 pgbench_onlyff17

start-bench-18:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 started", "tags": ["v18"]}' || true
	@docker compose up -d pgbench_ori18 pgbench_onlyff18

bench-all:
	@$(MAKE) start-bench-13
	@sleep 630
	@$(MAKE) stop-bench-13
	@sleep 10
	@$(MAKE) start-bench-17
	@sleep 630
	@$(MAKE) stop-bench-17
	@sleep 10
	@$(MAKE) start-bench-18
	@sleep 630
	@$(MAKE) stop-bench-18
	
down-13:
	@docker compose down -v postgres13 
	@rm -rf pg13_data/

down-17:
	@docker compose down -v postgres17 
	@rm -rf pg17_data/

down-18:
	@docker compose down -v postgres18 
	@rm -rf pg18_data/

clean:
	@docker compose down -v
	@rm -rf pg*data/

psql13:
	@docker compose exec -it -u postgres postgres13 psql -U postgres testdb

psql18:
	@docker compose exec -it -u postgres postgres18 psql -U postgres testdb

psql17:
	@docker compose exec -it -u postgres postgres17 psql -U postgres testdb

stop-bench-13:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 stopped", "tags": ["v13"]}' || true
	@docker compose stop pgbench_ori13 pgbench_onlyff13

stop-bench-17:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 stopped", "tags": ["v17"]}' || true
	@docker compose stop pgbench_ori17 pgbench_onlyff17

stop-bench-18:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 stopped", "tags": ["v18"]}' || true
	@docker compose stop pgbench_ori18 pgbench_onlyff18
