up:
	@docker compose up

upd:
	@docker compose up -d

build-pgbench:
	@docker compose build pgbench13 pgbench17 pgbench18

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

start-bench-13-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 original started", "tags": ["v13", "original"]}' || true
	@docker compose up -d pgbench_ori13

start-bench-13-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 fillfactor started", "tags": ["v13", "fillfactor"]}' || true
	@docker compose up -d pgbench_onlyff13

# start-bench-13:
# 	@curl -X POST http://localhost:3000/api/annotations \
# 		-H "Content-Type: application/json" \
# 		-u "admin:admin" \
# 		-d '{"text": "Benchmark v13 started", "tags": ["v13"]}' || true
# 	@docker compose up -d pgbench_ori13 pgbench_onlyff13 

start-bench-17-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 original started", "tags": ["v17", "original"]}' || true
	@docker compose up -d pgbench_ori17

start-bench-17-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 fillfactor started", "tags": ["v17", "fillfactor"]}' || true
	@docker compose up -d pgbench_onlyff17

# start-bench-17:
# 	@curl -X POST http://localhost:3000/api/annotations \
# 		-H "Content-Type: application/json" \
# 		-u "admin:admin" \
# 		-d '{"text": "Benchmark v17 started", "tags": ["v17"]}' || true
# 	@docker compose up -d pgbench_ori17 pgbench_onlyff17

start-bench-18-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 original started", "tags": ["v18", "original"]}' || true
	@docker compose up -d pgbench_ori18

start-bench-18-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 fillfactor started", "tags": ["v18", "fillfactor"]}' || true
	@docker compose up -d pgbench_onlyff18

# start-bench-18:
# 	@curl -X POST http://localhost:3000/api/annotations \
# 		-H "Content-Type: application/json" \
# 		-u "admin:admin" \
# 		-d '{"text": "Benchmark v18 started", "tags": ["v18"]}' || true
# 	@docker compose up -d pgbench_ori18 pgbench_onlyff18

bench-all:
	@$(MAKE) start-bench-13-ori
	@sleep 330
	@$(MAKE) stop-bench-13-ori
	@sleep 10
	@$(MAKE) start-bench-13-onlyff
	@sleep 330
	@$(MAKE) stop-bench-13-onlyff
	@sleep 10
	@$(MAKE) start-bench-17-ori
	@sleep 330
	@$(MAKE) stop-bench-17-ori
	@sleep 10
	@$(MAKE) start-bench-17-onlyff
	@sleep 330
	@$(MAKE) stop-bench-17-onlyff
	@sleep 10
	@$(MAKE) start-bench-18-ori
	@sleep 330
	@$(MAKE) stop-bench-18-ori
	@sleep 10
	@$(MAKE) start-bench-18-onlyff
	@sleep 330
	@$(MAKE) stop-bench-18-onlyff
	@sleep 10
	
docker-command:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Started Benchmark Script:$(SCRIPT) Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME)", "tags": ["v$(VERSION)", "$(DB)"]}' || true
	@sleep 10
	@docker run -d --rm \
		--name pgbench$(VERSION) \
		--network fillfactor_postgres_network \
		-e HOST=postgres$(VERSION) \
		-e POSTGRES_USER=postgres \
		-e POSTGRES_PASSWORD=postgres \
		-e POSTGRES_DB=$(DB) \
		-e PGPASSWORD=postgres \
		-e SCRIPT=$(SCRIPT) \
		-e CLIENTS=$(CLIENTS) \
		-e JOBS=$(JOBS) \
		-e TIME=$(TIME) \
		-e PROGRESS=$(PROGRESS) \
		-v $(PWD)/scripts$(SCRIPT):$(SCRIPT) \
		pgbench:$(VERSION)

	@sleep 60
	@sleep $(TIME)

	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Stopped Benchmark Script:$(SCRIPT) Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME)", "tags": ["v$(VERSION)", "$(DB)"]}' || true
	@sleep 5


bench-all-custom:
	@$(MAKE) docker-command VERSION=13 DB=ori13 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=13 DB=onlyff13 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=17 DB=ori17 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=17 DB=onlyff17 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=18 DB=ori18 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=18 DB=onlyff18 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)

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

stop-bench-13-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 original stopped", "tags": ["v13", "original"]}' || true
	@docker compose stop pgbench_ori13

stop-bench-13-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v13 fillfactor stopped", "tags": ["v13", "fillfactor"]}' || true
	@docker compose stop pgbench_onlyff13

# stop-bench-13:
# 	@$(MAKE) stop-bench-13-ori
# 	@$(MAKE) stop-bench-13-onlyff

stop-bench-17-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 original stopped", "tags": ["v17", "original"]}' || true
	@docker compose stop pgbench_ori17

stop-bench-17-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v17 fillfactor stopped", "tags": ["v17", "fillfactor"]}' || true
	@docker compose stop pgbench_onlyff17

# stop-bench-17:
# 	@$(MAKE) stop-bench-17-ori
# 	@$(MAKE) stop-bench-17-onlyff

stop-bench-18-ori:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 original stopped", "tags": ["v18", "original"]}' || true
	@docker compose stop pgbench_ori18

stop-bench-18-onlyff:
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Benchmark v18 fillfactor stopped", "tags": ["v18", "fillfactor"]}' || true
	@docker compose stop pgbench_onlyff18

# stop-bench-18:
# 	@$(MAKE) stop-bench-18-ori
# 	@$(MAKE) stop-bench-18-onlyff
