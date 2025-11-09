# PostgreSQL with Patroni, Envoy, and PgBouncer Fleet

Basic production setup with high availability and connection pooling.

```mermaid
graph TB
    subgraph "Client Layer"
        C1[Client App 1]
        C2[Client App 2]
        C3[Client App N]
    end

    subgraph "Load Balancer Layer"
        Envoy[Envoy Proxy<br/>:5432]
    end

    subgraph "Connection Pooling Layer"
        PGB1[PgBouncer 1<br/>:6432]
        PGB2[PgBouncer 2<br/>:6432]
        PGB3[PgBouncer 3<br/>:6432]
        PGB4[PgBouncer N<br/>:6432]
    end

    subgraph "Database Cluster"
        subgraph "Patroni Cluster"
            PAT1["Patroni Primary<br/>PostgreSQL Master<br/>:5432"]
            PAT2["Patroni Replica 1<br/>PostgreSQL Standby<br/>:5432"]
            PAT3["Patroni Replica 2<br/>PostgreSQL Standby<br/>:5432"]
        end
    end

    subgraph "Distributed Configuration Store"
        DCS[(etcd/Consul/Zookeeper<br/>Patroni DCS)]
    end

    C1 --> Envoy
    C2 --> Envoy
    C3 --> Envoy

    Envoy --> PGB1
    Envoy --> PGB2
    Envoy --> PGB3
    Envoy --> PGB4

    PGB1 --> PAT1
    PGB2 --> PAT1
    PGB3 --> PAT1
    PGB4 --> PAT1

    PAT1 -.->|Streaming Replication| PAT2
    PAT1 -.->|Streaming Replication| PAT3

    PAT1 <-->|Health Checks<br/>Leader Election| DCS
    PAT2 <-->|Health Checks<br/>Monitor Leader| DCS
    PAT3 <-->|Health Checks<br/>Monitor Leader| DCS

    PGB1 -.->|Health Check| DCS
    PGB2 -.->|Health Check| DCS
    PGB3 -.->|Health Check| DCS
    PGB4 -.->|Health Check| DCS

    style PAT1 fill:#2ecc71,stroke:#27ae60,stroke-width:3px
    style PAT2 fill:#3498db,stroke:#2980b9,stroke-width:2px
    style PAT3 fill:#3498db,stroke:#2980b9,stroke-width:2px
    style Envoy fill:#9b59b6,stroke:#8e44ad,stroke-width:3px
    style DCS fill:#e74c3c,stroke:#c0392b,stroke-width:2px
```

## Components

- **Client Layer**: Applications connecting to the database
- **Envoy Proxy**: Single entrypoint for all client connections, load balances across PgBouncers
- **PgBouncer Fleet**: Multiple connection poolers that reduce connection overhead to PostgreSQL
- **Patroni Cluster**:
  - Primary node (green) handling writes
  - Replica nodes (blue) for read scaling
  - Streaming replication between nodes
- **DCS (etcd/Consul/Zookeeper)**: Stores cluster state, handles leader election, enables automatic failover

## Features

- High availability via Patroni automatic failover
- Connection pooling via PgBouncer fleet
- Load distribution via Envoy
- Streaming replication for data redundancy
