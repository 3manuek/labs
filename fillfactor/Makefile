up:
	@docker compose up

upd:
	@docker compose up -d

up-back:
	@docker compose up -d prometheus grafana 

up-13:
	@docker compose up -d postgres13 postgres_exporter13 sql_exporter

up-18:
	@docker compose up -d postgres18 postgres_exporter18 sql_exporter

up-17:
	@docker compose up -d postgres17 postgres_exporter17 sql_exporter

start-bench-13:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 started", "tags": ["Status v13 benchmark"]}' || true
	@docker compose up -d pgbench_ori13 pgbench_onlyff13 

start-bench-17:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 started", "tags": ["Status v17 benchmark"]}' || true
	@docker compose up -d pgbench_ori17 pgbench_onlyff17

start-bench-18:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 started", "tags": ["Status v18 benchmark"]}' || true
	@docker compose up -d pgbench_ori18 pgbench_onlyff18

down-13:
	@docker compose down -v postgres13 postgres_exporter13
	@rm -rf pg13_data/

down-17:
	@docker compose down -v postgres17 postgres_exporter17
	@rm -rf pg17_data/

down-18:
	@docker compose down -v postgres18 postgres_exporter18
	@rm -rf pg18_data/

down:
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
		-d '{"text": "Benchmark v13 stopped", "tags": ["Status v13 benchmark"]}' || true
	@docker compose stop pgbench_ori13 pgbench_onlyff13

stop-bench-17:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 stopped", "tags": ["Status v17 benchmark"]}' || true
	@docker compose stop pgbench_ori17 pgbench_onlyff17

stop-bench-18:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 stopped", "tags": ["Status v18 benchmark"]}' || true
	@docker compose stop pgbench_ori18 pgbench_onlyff18

stop-bench:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark stopped", "tags": ["Status v13 benchmark", "Status v18 benchmark", "Status v17 benchmark"]}' || true
	@docker compose stop  pgbench_ori13 pgbench_onlyff13 pgbench_ori18 pgbench_onlyff18 pgbench_ori17 pgbench_onlyff17