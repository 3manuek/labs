

up:
	docker compose up

down:
	docker compose down

clean:
	docker compose down -v
	rm -fr patroni*data
	rm -fr pgbouncer_conf

build:
	docker compose build --no-cache

switchover:
	docker compose exec -it patroni1 patronictl -c /etc/patroni/patroni.yml switchover --force

list:
	docker compose exec -it patroni1 patronictl -c /etc/patroni/patroni.yml list