# pool-single-thread — PgBouncer vs ProxySQL single-thread benchmark lab
# Usage: make help
include .env

RUN ?= default
export RUN TARGETS WORKLOADS CLIENTS REPEATS PROTOCOL DURATION WARMUP JOBS SAMPLING \
       W3_SPAN W3_SLEEP_MS MAX_TRIES FORCE NOW KEEP_TXLOG RETRY_FAILED VACUUM

COMPOSE := docker compose
BENCH   := ./scripts/bench.sh

.PHONY: help up down restart-poolers clean build ps logs urls seed-status reseed \
        bench bench-bg pause resume status summary report smoke reset-run \
        psql psql-pgbouncer psql-proxysql pgbouncer-admin proxysql-admin

help: ## show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------------------- stack
build: ## build the pgbouncer image
	@$(COMPOSE) build --progress=plain pgbouncer

up: build ## start the whole stack (seeds the database on first start)
	@$(COMPOSE) up -d
	@echo "waiting for seed / poolers to be healthy..."
	@for c in pst-postgres pst-pgbouncer pst-proxysql; do \
	  until [ "$$(docker inspect -f '{{.State.Health.Status}}' $$c 2>/dev/null)" = healthy ]; do sleep 2; done; \
	  echo "  $$c healthy"; done
	@$(MAKE) --no-print-directory urls

down: ## stop the stack (keeps data volumes)
	@$(COMPOSE) down

restart-poolers: ## restart pgbouncer and proxysql
	@docker restart pst-pgbouncer pst-proxysql >/dev/null && echo restarted

clean: ## stop the stack AND delete volumes (database, prometheus, grafana) — asks first
	@read -p "Delete all lab volumes (database, metrics, dashboards state)? [y/N] " a; [ "$$a" = y ] || exit 1
	@$(COMPOSE) down -v --remove-orphans

ps: ## container status
	@$(COMPOSE) ps

logs: ## follow logs (S=service to filter)
	@$(COMPOSE) logs -f --tail=100 $(S)

urls: ## print UI endpoints
	@echo "Grafana     http://localhost:$(GRAFANA_PORT)  (admin/admin)"
	@echo "Prometheus  http://localhost:$(PROMETHEUS_PORT)"
	@echo "Pushgateway http://localhost:$(PUSHGATEWAY_PORT)"
	@echo "cAdvisor    http://localhost:$(CADVISOR_PORT)"

seed-status: ## show seed info of the template database
	@docker exec pst-postgres psql -U postgres -d postgres -c "select datname, pg_size_pretty(pg_database_size(datname)) size from pg_database where datname like 'bench%'"
	@docker exec pst-postgres psql -U postgres -d bench -c "table lab_seed"

reseed: ## drop the database volume and seed again (e.g. after changing SCALE) — asks first
	@read -p "Drop the database volume and re-seed with SCALE=$(SCALE)? [y/N] " a; [ "$$a" = y ] || exit 1
	@$(COMPOSE) rm -sf postgres pgbouncer proxysql
	@docker volume rm -f pool-single-thread_pgdata
	@$(MAKE) --no-print-directory up

# ----------------------------------------------------------------- benchmark
bench: ## run (or continue) the matrix: RUN TARGETS WORKLOADS CLIENTS REPEATS PROTOCOL DURATION WARMUP FORCE=1
	@$(BENCH) run

bench-bg: ## same as bench, detached; log in results/$(RUN)/runner.log
	@mkdir -p results/$(RUN)
	@nohup $(BENCH) run > results/$(RUN)/runner.log 2>&1 &
	@echo "runner started in background -> tail -f results/$(RUN)/runner.log"

pause: ## pause after the current cell (NOW=1 aborts the current cell; it is re-run on resume)
	@$(BENCH) pause

resume: ## clear the pause flag and continue the run
	@$(BENCH) resume

status: ## ledger of the run
	@$(BENCH) status

summary: ## rebuild results/$(RUN)/summary.csv
	@$(BENCH) summary

report: summary ## build results/$(RUN)/report.html
	@RUN=$(RUN) ./scripts/build_report.sh

smoke: ## 10s sanity run of every workload/target (RUN=smoke)
	@RUN=smoke CLIENTS=8 DURATION=10 WARMUP=2 REPEATS=1 $(BENCH) run

reset-run: ## delete results/$(RUN) (ledger + results) — asks first
	@read -p "Delete results/$(RUN)? [y/N] " a; [ "$$a" = y ] || exit 1
	@rm -rf results/$(RUN) && echo "results/$(RUN) removed"

# ----------------------------------------------------------------- shells
psql: ## psql to postgres (direct)
	@docker exec -it pst-postgres psql -U postgres -d bench

psql-pgbouncer: ## psql to bench through pgbouncer
	@docker exec -it -e PGPASSWORD=bench pst-postgres psql -h pgbouncer -p 6432 -U bench -d bench

psql-proxysql: ## psql to bench through proxysql
	@docker exec -it -e PGPASSWORD=bench pst-postgres psql -h proxysql -p 6133 -U bench -d bench

pgbouncer-admin: ## pgbouncer admin console (SHOW POOLS; SHOW STATS; ...)
	@docker exec -it -e PGPASSWORD=admin pst-postgres psql -h pgbouncer -p 6432 -U admin -d pgbouncer

proxysql-admin: ## proxysql admin (select * from stats_pgsql_connection_pool; ...)
	@docker exec -it -e PGPASSWORD=radmin pst-postgres psql -h proxysql -p 6132 -U radmin -d admin
