up:
	@docker compose up

upd:
	@docker compose up -d

up-back:
	@docker compose up postgres13 postgres18 prometheus grafana postgres_exporter13 postgres_exporter18 sql_exporter

start-bench:
	@docker compose up -d pgbench_ori13 pgbench_onlyff13 pgbench_ori18 pgbench_onlyff18

down:
	@docker compose down -v
	@rm -rf pg*data/

psql13:
	@docker compose exec -it -u postgres postgres13 psql -U postgres testdb

psql18:
	@docker compose exec -it -u postgres postgres18 psql -U postgres testdb

stop-bench:
	@docker compose stop  pgbench_ori13 pgbench_onlyff13 pgbench_ori18 pgbench_onlyff18