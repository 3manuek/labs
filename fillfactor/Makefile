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

start-bench-13:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 started", "tags": ["Status benchmark"]}' || true
	@docker compose up -d pgbench_ori13 pgbench_onlyff13 

start-bench-18:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 started", "tags": ["Status benchmark"]}' || true
	@docker compose up -d pgbench_ori18 pgbench_onlyff18

down:
	@docker compose down -v
	@rm -rf pg*data/

psql13:
	@docker compose exec -it -u postgres postgres13 psql -U postgres testdb

psql18:
	@docker compose exec -it -u postgres postgres18 psql -U postgres testdb

stop-bench:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark stopped", "tags": ["Status benchmark"]}' || true
	@docker compose stop  pgbench_ori13 pgbench_onlyff13 pgbench_ori18 pgbench_onlyff18