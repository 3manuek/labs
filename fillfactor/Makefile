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

	
docker-command:
	@mkdir -p logs
	@echo "Started Benchmark $(VERSION) $(DB) Script:$(SCRIPT) Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME) Var1:$(VAR1)"
	@sleep 10
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Started Benchmark Script:$(SCRIPT) Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME) Var1:$(VAR1)", "tags": ["v$(VERSION)", "$(DB)"]}' || true
	@docker run --rm \
		--name pgbench$(VERSION)_$(DB) \
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
		-e VAR1=$(VAR1) \
		-v $(PWD)/scripts$(SCRIPT):$(SCRIPT) \
		pgbench:$(VERSION) > logs/pgbench$(VERSION)_$(DB).log 2>&1
		
	@sleep 45
	@echo
	@curl -X POST http://localhost:3000/api/annotations \
		-H "Content-Type: application/json" \
		-u "admin:admin" \
		-d '{"text": "Stopped Benchmark Script:$(SCRIPT) Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME) Var1:$(VAR1)", "tags": ["v$(VERSION)", "$(DB)"]}' || true
	@echo

build-graph:
	@./build_graph.sh "Clients:$(CLIENTS) Jobs:$(JOBS) Time:$(TIME) Records:$(VAR1)" "c$(CLIENTS)_j$(JOBS)_t$(TIME)_records$(VAR1)"

bench-all-custom:
	@$(MAKE) docker-command VERSION=13 DB=ori13 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=17 DB=ori17 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=18 DB=ori18 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=13 DB=onlyff13 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=17 DB=onlyff17 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) docker-command VERSION=18 DB=onlyff18 SCRIPT=$(SCRIPT) CLIENTS=$(CLIENTS) JOBS=$(JOBS) TIME=$(TIME) PROGRESS=$(PROGRESS)
	@$(MAKE) build-graph

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
