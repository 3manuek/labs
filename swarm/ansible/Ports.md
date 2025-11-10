https://raw.githubusercontent.com/patroni/patroni/refs/heads/master/docker-compose.yml



TCP 2377: For cluster management communications.
TCP/UDP 7946: For communication among nodes.
UDP 4789: For overlay network traffic.

Ensure that Docker Swarm's overlay network is correctly set up and that ports 2379 (client) and 2380 (peer) are available for etcd communication.

5432 for Postgres communications (replication)
8008 for Patroni

Required ports between nodes in AWS:

| Port    | Protocol  | Purpose                           |
|---------|-----------|-----------------------------------|
| 2377    | TCP       | Docker Swarm cluster management   |
| 7946    | TCP/UDP   | Docker Swarm node communication   |
| 4789    | UDP       | Docker Swarm overlay network      |
| 2379    | TCP       | etcd client communication         |
| 2380    | TCP       | etcd peer communication          |
| 5432    | TCP       | PostgreSQL replication           |
| 8008    | TCP       | Patroni API and control          |

Note: These ports should be opened in your AWS Security Groups for the instances that are part of your cluster. Ensure that:
- All ports are opened between nodes in the same cluster
- Consider restricting access to these ports from outside the cluster for security
- For production environments, it's recommended to use private subnets with VPC for internal communication

