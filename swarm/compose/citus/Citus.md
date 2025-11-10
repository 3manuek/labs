Deployment and Setup

Looks like Citus is not strictly compatible with Docker Stack https://github.com/citusdata/docker/issues/70
https://github.com/citusdata/docker/issues/70#issuecomment-393699066
https://medium.com/@bhadange.atharv/citus-multi-node-setup-69c900754da3

https://github.com/citusdata/citus-example-ad-analytics/blob/master/docker-compose.yml

Deploy the stack:

In your Docker Swarm environment run:


```bash
docker stack deploy -c docker-stack.yml citus_cluster
```

Initialize the Citus coordinator:

Once the containers are running, connect to the coordinator:


```bash
docker exec -it $(docker ps --filter "name=citus_cluster_coordinator" -q) psql -U postgres -d mydb
```

Inside psql, run these commands:

```sql

-- Create the Citus extension if not already created:
CREATE EXTENSION IF NOT EXISTS citus;

-- Register the worker nodes (Docker’s internal DNS lets the coordinator resolve service names):
SELECT master_add_node('worker1', 5432);
SELECT master_add_node('worker2', 5432);
```

Your Citus cluster is now running in a distributed setup with resource limits defined by cgroups (via Docker’s deploy.resources).

https://github.com/Kelvinrr/docker-postgis-citus/blob/master/docker-compose.yml



```sql
SELECT create_distributed_table('tenants',   'id');
SELECT create_distributed_table('questions',   'id');
```