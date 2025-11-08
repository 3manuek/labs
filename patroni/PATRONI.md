# Patroni implementations


### Patroni Callbacks

This shows the steps performed by `pgbouncer_conf.sh` when Patroni triggers it as a callback on start or role change. The script queries Patroni for the current leader, updates PgBouncer’s configuration, reloads it, and resumes pools in order.

The scripts emulates our _seamless switchover_ process.

```mermaid
sequenceDiagram
    autonumber
    participant Patroni as Patroni (callback)
    participant pgbouncer_conf as pgbouncer_conf.sh
    participant Patroni_API as Patroni REST API
    participant PgBouncer as PgBouncer
    participant Config as /etc/pgbouncer/pgbouncer.ini

    Patroni->>pgbouncer_conf: Trigger callback script<br/>(on_start/on_role_change)
    pgbouncer_conf->>Patroni_API: GET /cluster (find new writer)
    Patroni_API-->>pgbouncer_conf: Return cluster members<br/>(with current leader)
    alt If leader is found
        pgbouncer_conf->>PgBouncer: PAUSE all pools
        pgbouncer_conf->>Config: Update pgbouncer.ini with new writer
        pgbouncer_conf->>Config: Copy userlist.txt
        pgbouncer_conf->>PgBouncer: RELOAD config
        pgbouncer_conf->>PgBouncer: RESUME all pools
    else No leader
        pgbouncer_conf-->>pgbouncer_conf: Exit with error
    end
```



