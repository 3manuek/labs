
# PGBouncer

One strategy is to place one pgbouncer alongside each Postgres node. The HAProxy can redirect to pgbouncer and do the
check on the Patroni node (Postgres).


```yaml

  postgres1:
    image: ${SPILO_TEST_IMAGE:-spilo}
    networks:
      swarmlab_net:
        aliases:
          - "postgres1" 
    env_file:
      - docker/patroni.env
    hostname: postgres1
    environment:
      <<: *haproxy_env
      PATRONI_NAME: "postgres1"
    ports:
      - "15432:5432" # this exposes Postgres, although it should go only through pgbouncer
      - 8008
    depends_on:
      - etcd1
      - etcd2
      - etcd3
    deploy:
      placement:
        constraints:
          - "node.role == manager"
          - "node.labels.role == postgres1"

  # --- New Global pgbouncer Services ---
  pgbouncer1:
    image: pgbouncer/pgbouncer:latest
    networks:
      - swarmlab_net
    ports:
      - "16432:6432"  # Expose pgbouncer on port 6001 for writer connections
    volumes:
      - ./docker/pgbouncer1.ini:/etc/pgbouncer/pgbouncer.ini:ro
    # Optionally, add environment variables or a command line override here if needed for dynamic config
    deploy:
      restart_policy:
        condition: any
      placement:
        - "node.labels.role == postgres1"
    depends_on:
      - postgres1  # assuming postgres1 is your designated writer

```


`pgbouncer.ini`:
 
```ini
[databases]
; Replace "mydb" with your actual database name.
swarmlab = host=postgres1 port=5432 dbname=mydb pool_mode=session

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = session
max_client_conn = 100
default_pool_size = 20
; Additional settings can be added here
```



`userlist.txt`:

```txt
"postgres" "md5xxxx
```
