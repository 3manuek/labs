
- [Docker Compose for Spilo](https://github.com/zalando/spilo/blob/master/postgres-appliance/tests/docker-compose.yml)
- [Compose Citus](https://github.com/patroni/patroni/blob/master/docker-compose-citus.yml)
- [HAProxy](https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/)


```bash
ansible-playbook 005_spilo_image.yaml
ansible-playbook 105_spilo_deploy.yaml
```

Requires to install a client for `psql`.

Connect and execute:

```bash
CREATE EXTENSION IF NOT EXISTS timescaledb;
```


```mermaid
flowchart TD
  subgraph Node1 Manager
    E1[etcd1]
    P1[postgres1]
    HA1[haproxy]
  end

  subgraph Node2 Worker
    E2[etcd2]
    P2[postgres2]
    HA2[haproxy]
  end

  subgraph Node3 Worker
    E3[etcd3]
    P3[postgres3]
    HA3[haproxy]
  end

  subgraph Overlay Network
    BN[swarmlab_net]
  end

  %% Connect each service to the overlay network
  E1 --- BN
  P1 --- BN
  HA1 --- BN

  E2 --- BN
  P2 --- BN
  HA2 --- BN

  E3 --- BN
  P3 --- BN
  HA3 --- BN
```