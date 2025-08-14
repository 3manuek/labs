up:
	@docker compose up

upd:
	@docker compose up -d

upstart:
	@make down
	@make up 

down:
	@docker compose down -v
	@rm -rf postgres_1*data/

psql:
	@docker compose exec -it -u postgres postgres_16 psql conductor