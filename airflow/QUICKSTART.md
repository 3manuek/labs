# Quick Start Guide

## Summary

This laboratory provides a complete Docker Compose setup with PostgreSQL 18 and Apache Airflow integration.

## What's Included

- PostgreSQL 18 with sample data (users, products, orders)
- Apache Airflow 2.10.3 with example DAG
- Comprehensive Makefile for easy management
- Automatic database initialization
- Pre-configured connections

## Getting Started

### Option 1: Complete Setup (Recommended)

```bash
make init
```

This single command will:
- Start all services
- Wait for them to be healthy
- Configure the PostgreSQL connection
- Verify the setup

### Option 2: Manual Steps

```bash
# Start services
make start

# Wait for services to be ready
make wait-for-services

# Setup Airflow connection
make setup-connection

# Verify everything works
make check-health
make test-db
```

## Access Points

- **Airflow UI**: http://localhost:8081
  - Username: `admin`
  - Password: `admin`

- **PostgreSQL**: localhost:5432
  - User: `airflow`
  - Password: `airflow`
  - Database: `sample_data`

## Common Commands

```bash
make help              # Show all available commands
make status            # Check service status
make check-health      # Verify all services are healthy
make test-db           # View sample database data

make list-dags         # List all Airflow DAGs
make unpause-dag       # Enable the example DAG
make trigger-dag       # Manually trigger DAG execution

make logs              # View all service logs
make logs-airflow      # View Airflow webserver logs
make logs-scheduler    # View Airflow scheduler logs
make logs-postgres     # View PostgreSQL logs

make db-connect        # Connect to sample_data database
make shell-airflow     # Open shell in Airflow container
make shell-postgres    # Open shell in PostgreSQL container

make info              # Show connection information
make verify            # Run full verification

make stop              # Stop all services
make restart           # Restart all services
make clean             # Stop and remove containers (keeps data)
make clean-all         # Remove everything including data
```

## Example DAG

The `postgres_example_dag` demonstrates:

1. Creating a sales report table
2. Inserting daily metrics
3. Processing pending orders
4. Calculating daily revenue
5. Checking low stock products
6. Updating order statuses
7. Querying top-selling products

### Run the Example DAG

```bash
# Unpause the DAG
make unpause-dag

# Trigger a manual run
make trigger-dag

# View logs
make logs-scheduler
```

Or visit http://localhost:8081 and use the UI.

## Database Schema

### Tables

- **users**: User accounts (5 sample users)
- **products**: Product catalog (10 sample products)
- **orders**: Customer orders (8 sample orders)
- **order_items**: Order line items

### Views

- **order_summary**: Orders with user information
- **product_sales**: Product sales statistics

## Troubleshooting

### Services not starting

```bash
make clean-all
make init
```

### Check service health

```bash
make check-health
```

### View logs for errors

```bash
make logs
```

### Port already in use

If you get a port conflict, edit `docker-compose.yml` and change the port mappings.

## Project Structure

```
.
├── Makefile                    # Management commands
├── docker-compose.yml          # Service orchestration
├── README.md                   # Detailed documentation
├── QUICKSTART.md              # This file
├── init-scripts/
│   └── 01-init.sql            # Database initialization
├── dags/
│   └── postgres_example_dag.py # Example Airflow DAG
├── logs/                       # Airflow logs
└── plugins/                    # Airflow plugins
```

## Next Steps

1. Explore the sample data: `make test-db`
2. Visit the Airflow UI: http://localhost:8081
3. Run the example DAG
4. Create your own DAGs in the `dags/` directory
5. Modify the database schema in `init-scripts/01-init.sql`

## Verified Features

All features have been tested and verified:

- ✅ PostgreSQL 18 with proper data directory configuration
- ✅ Database initialization with sample data
- ✅ Airflow webserver accessible on port 8081
- ✅ Airflow scheduler running
- ✅ PostgreSQL connection configured in Airflow
- ✅ Example DAG executing successfully
- ✅ All Makefile commands working
- ✅ Health checks passing
- ✅ Database queries working
- ✅ DAG triggering and execution

Enjoy your Apache Airflow laboratory!
