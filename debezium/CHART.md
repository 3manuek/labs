# Architecture & Flow Diagrams

This document contains comprehensive Mermaid diagrams illustrating the CDC pipeline architecture, data flows, and operational patterns.

## Table of Contents
1. [System Architecture](#system-architecture) - High-level component view
2. [Data Flow Sequence](#data-flow-sequence) - Step-by-step data movement
3. [CDC Event Structure](#cdc-event-structure) - Debezium event format
4. [Container Dependencies](#container-dependencies) - Service startup order
5. [Network Topology](#network-topology) - Network configuration
6. [Change Data Capture Flow](#change-data-capture-flow) - Detailed CDC process
7. [Health Check Flow](#health-check-flow) - Container health checks
8. [Operations Overview](#operations-overview) - INSERT/UPDATE/DELETE handling

---

## System Architecture

```mermaid
graph TB
    subgraph "Source"
        PG[(PostgreSQL 18<br/>Logical Replication)]
    end

    subgraph "Message Broker"
        ZK[ZooKeeper]
        K[Kafka<br/>Topic: postgres.public.users]
        ZK --> K
    end

    subgraph "CDC Layer"
        DB[Debezium Connect<br/>PostgreSQL Connector]
    end

    subgraph "Consumer Layer"
        PC[Python Consumer<br/>kafka-python + clickhouse-driver]
    end

    subgraph "Destination"
        CH[(ClickHouse<br/>MergeTree Engine)]
    end

    PG -->|WAL Stream| DB
    DB -->|CDC Events| K
    K -->|Consume| PC
    PC -->|Insert| CH

    style PG fill:#4A90E2
    style K fill:#E2A430
    style DB fill:#50C878
    style PC fill:#9B59B6
    style CH fill:#E74C3C
```

## Data Flow Sequence

```mermaid
sequenceDiagram
    participant User
    participant PostgreSQL
    participant Debezium
    participant Kafka
    participant Consumer
    participant ClickHouse

    User->>PostgreSQL: INSERT/UPDATE/DELETE
    activate PostgreSQL
    PostgreSQL->>PostgreSQL: Write to WAL
    PostgreSQL-->>Debezium: Stream WAL Changes
    deactivate PostgreSQL

    activate Debezium
    Debezium->>Debezium: Parse WAL
    Debezium->>Debezium: Transform to CDC Event
    Debezium->>Kafka: Publish Event
    deactivate Debezium

    activate Kafka
    Kafka->>Kafka: Store in Topic
    Kafka-->>Consumer: Poll Events
    deactivate Kafka

    activate Consumer
    Consumer->>Consumer: Deserialize JSON
    Consumer->>Consumer: Extract 'after' fields
    Consumer->>Consumer: Convert timestamp
    Consumer->>ClickHouse: INSERT INTO users
    deactivate Consumer

    activate ClickHouse
    ClickHouse->>ClickHouse: Write to MergeTree
    ClickHouse-->>User: Query Results
    deactivate ClickHouse
```

## CDC Event Structure

```mermaid
graph LR
    subgraph "Debezium CDC Event"
        A[before: null/object]
        B[after: object]
        C[source: metadata]
        D[op: c/u/d/r]
        E[ts_ms: timestamp]
    end

    subgraph "After Payload"
        F[id: int]
        G[name: string]
        H[email: string]
        I[age: int]
        J[created_at: microseconds]
    end

    B --> F
    B --> G
    B --> H
    B --> I
    B --> J

    style B fill:#50C878
    style F fill:#E2A430
    style G fill:#E2A430
    style H fill:#E2A430
    style I fill:#E2A430
    style J fill:#E2A430
```

## Container Dependencies

```mermaid
graph TD
    subgraph "Startup Order"
        Z[ZooKeeper<br/>Port: 2181]
        P[PostgreSQL<br/>Port: 5432]
        C[ClickHouse<br/>Ports: 8123, 9000]

        Z -->|healthy| K[Kafka<br/>Port: 9092]
        K -->|healthy| D[Debezium<br/>Port: 8083]
        P -->|healthy| D
        C -->|healthy| D

        K -->|healthy| PC[Python Consumer]
        C -->|healthy| PC
    end

    style Z fill:#95A5A6
    style P fill:#4A90E2
    style C fill:#E74C3C
    style K fill:#E2A430
    style D fill:#50C878
    style PC fill:#9B59B6
```

## Network Topology

```mermaid
graph TB
    subgraph "debezium-net Bridge Network"
        subgraph "Data Sources"
            PG[PostgreSQL<br/>postgres:5432]
        end

        subgraph "Streaming Platform"
            ZK[ZooKeeper<br/>zookeeper:2181]
            KF[Kafka<br/>kafka:29092<br/>localhost:9092]
        end

        subgraph "Processing"
            DB[Debezium<br/>debezium:8083]
            CON[Consumer<br/>kafka-clickhouse-consumer]
        end

        subgraph "Analytics"
            CH[ClickHouse<br/>clickhouse:8123<br/>clickhouse:9000]
        end

        PG -.->|TCP| DB
        ZK -.->|TCP| KF
        KF -.->|TCP| DB
        KF -.->|TCP| CON
        DB -.->|HTTP API| EXT[External Access<br/>localhost:8083]
        CH -.->|HTTP| EXT2[External Access<br/>localhost:8123]
        PG -.->|PostgreSQL| EXT3[External Access<br/>localhost:5432]
        KF -.->|Kafka| EXT4[External Access<br/>localhost:9092]
        CON -.->|TCP| CH
    end

    style PG fill:#4A90E2
    style KF fill:#E2A430
    style DB fill:#50C878
    style CON fill:#9B59B6
    style CH fill:#E74C3C
```

## Change Data Capture Flow

```mermaid
flowchart LR
    subgraph "PostgreSQL"
        T[users table]
        W[Write-Ahead Log<br/>wal_level=logical]
        T -->|writes| W
    end

    subgraph "Debezium"
        R[Replication Slot]
        P[pgoutput Plugin]
        T1[Transform]

        W -->|stream| R
        R -->|decode| P
        P -->|enrich| T1
    end

    subgraph "Kafka Topic"
        PT[postgres.public.users]
        T1 -->|publish| PT
    end

    subgraph "Consumer"
        C[Poll Messages]
        D[Deserialize]
        E[Extract Data]
        F[Transform DateTime]

        PT -->|consume| C
        C --> D
        D --> E
        E --> F
    end

    subgraph "ClickHouse"
        I[INSERT Statement]
        M[MergeTree Table]

        F --> I
        I --> M
    end

    style W fill:#4A90E2
    style P fill:#50C878
    style PT fill:#E2A430
    style F fill:#9B59B6
    style M fill:#E74C3C
```

## Health Check Flow

```mermaid
graph TD
    Start[Docker Compose Up]

    Start --> C1{ZooKeeper<br/>Health Check}
    C1 -->|unhealthy| W1[Wait 10s]
    W1 --> C1
    C1 -->|healthy| C2{Kafka<br/>Health Check}

    C2 -->|unhealthy| W2[Wait 10s]
    W2 --> C2
    C2 -->|healthy| C3{PostgreSQL<br/>Health Check}

    C3 -->|unhealthy| W3[Wait 10s]
    W3 --> C3
    C3 -->|healthy| C4{ClickHouse<br/>Health Check}

    C4 -->|unhealthy| W4[Wait 10s]
    W4 --> C4
    C4 -->|healthy| S1[Start Debezium]
    C4 -->|healthy| S2[Start Consumer]

    S1 --> Ready[System Ready]
    S2 --> Ready

    style C1 fill:#95A5A6
    style C2 fill:#E2A430
    style C3 fill:#4A90E2
    style C4 fill:#E74C3C
    style Ready fill:#50C878
```

## Operations Overview

```mermaid
graph TB
    subgraph "INSERT Operation"
        I1[User inserts row] -->|SQL| I2[PostgreSQL writes to WAL]
        I2 --> I3[Debezium captures INSERT]
        I3 --> I4[op: 'c' for create]
        I4 --> I5[after: full record]
        I5 --> I6[Consumer INSERTs to ClickHouse]
    end

    subgraph "UPDATE Operation"
        U1[User updates row] -->|SQL| U2[PostgreSQL writes to WAL]
        U2 --> U3[Debezium captures UPDATE]
        U3 --> U4[op: 'u' for update]
        U4 --> U5[before: old values<br/>after: new values]
        U5 --> U6[Consumer INSERTs to ClickHouse<br/>MergeTree handles duplicates]
    end

    subgraph "DELETE Operation"
        D1[User deletes row] -->|SQL| D2[PostgreSQL writes to WAL]
        D2 --> D3[Debezium captures DELETE]
        D3 --> D4[op: 'd' for delete]
        D4 --> D5[before: deleted record<br/>after: null]
        D5 --> D6[Consumer skips<br/>delete.enabled: false]
    end

    style I3 fill:#50C878
    style U3 fill:#E2A430
    style D3 fill:#E74C3C
```
