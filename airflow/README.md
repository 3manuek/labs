# Apache Airflow with PostgreSQL 18 Integration

This project provides a complete Docker Compose setup for Apache Airflow integrated with PostgreSQL 18, including example tables, data, and DAGs.

## Architecture

- **PostgreSQL 18**: Database server with two databases:
  - `airflow`: Airflow metadata database
  - `sample_data`: Application database with example tables
- **Apache Airflow 2.10.3**: Workflow orchestration with LocalExecutor
  - Webserver UI (port 8081)
  - Scheduler
  - Example DAG for PostgreSQL operations

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Start the services

```bash
docker-compose up -d
```

This will:
- Start PostgreSQL 18
- Initialize the `sample_data` database with example tables and data
- Initialize Airflow metadata database
- Start Airflow webserver and scheduler

### 2. Access Airflow UI

Open your browser and navigate to: http://localhost:8081

**Default credentials:**
- Username: `admin`
- Password: `admin`

### 3. Configure PostgreSQL Connection in Airflow

Before running the example DAG, you need to configure the PostgreSQL connection:

1. Go to Airflow UI: http://localhost:8081
2. Navigate to **Admin** > **Connections**
3. Click the **+** button to add a new connection
4. Fill in the following details:
   - **Connection Id**: `postgres_sample`
   - **Connection Type**: `Postgres`
   - **Host**: `postgres`
   - **Schema**: `sample_data`
   - **Login**: `airflow`
   - **Password**: `airflow`
   - **Port**: `5432`
5. Click **Save**

### 4. Run the Example DAG

1. In the Airflow UI, find the DAG named `postgres_example_dag`
2. Toggle the DAG to "On" (switch on the left side)
3. Click the play button to trigger the DAG manually

## Database Schema

The `sample_data` database includes the following tables:

### Tables

- **users**: User accounts with email and login information
- **products**: Product catalog with pricing and inventory
- **orders**: Customer orders with status tracking
- **order_items**: Line items for each order (junction table)

### Views

- **order_summary**: Aggregated view of orders with user information
- **product_sales**: Product sales statistics and revenue

### Sample Data

- 5 users
- 10 products across various categories
- 8 orders with multiple items
- Realistic timestamps and relationships

## Example DAG Operations

The `postgres_example_dag` performs the following operations:

1. Creates a `daily_sales_report` table
2. Inserts daily sales metrics
3. Processes pending orders
4. Calculates daily revenue
5. Checks for low-stock products
6. Updates old pending orders to 'processing' status
7. Queries top-selling products

## Accessing PostgreSQL Directly

Connect to PostgreSQL from your host machine:

```bash
psql -h localhost -p 5432 -U airflow -d sample_data
```

Password: `airflow`

Or use Docker:

```bash
docker exec -it postgres18 psql -U airflow -d sample_data
```

### Example Queries

```sql
-- View all orders with user information
SELECT * FROM order_summary;

-- Get product sales statistics
SELECT * FROM product_sales ORDER BY total_revenue DESC;

-- Check users who made orders
SELECT DISTINCT u.username, u.email, COUNT(o.order_id) as order_count
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username, u.email
ORDER BY order_count DESC;
```

## Project Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── init-scripts/
│   └── 01-init.sql            # PostgreSQL initialization script
├── dags/
│   └── postgres_example_dag.py # Example Airflow DAG
├── logs/                       # Airflow logs (auto-generated)
├── plugins/                    # Airflow plugins (optional)
└── README.md                   # This file
```

## Stopping the Services

```bash
docker-compose down
```

To remove volumes (deletes all data):

```bash
docker-compose down -v
```

## Troubleshooting

### Airflow webserver not accessible

Wait a few minutes for Airflow to initialize. Check logs:

```bash
docker-compose logs airflow-webserver
```

### Database connection errors in DAG

Make sure you've configured the `postgres_sample` connection in Airflow UI as described in step 3.

### Check PostgreSQL logs

```bash
docker-compose logs postgres
```

### Reset everything

```bash
docker-compose down -v
docker-compose up -d
```

## Customization

### Adding More Sample Data

Edit `init-scripts/01-init.sql` and restart:

```bash
docker-compose down -v
docker-compose up -d
```

### Creating New DAGs

Add Python files to the `dags/` directory. Airflow will automatically detect them.

### Changing Airflow Configuration

Modify the environment variables in `docker-compose.yml` under the Airflow services.

## Useful Commands

```bash
# View all running services
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f airflow-scheduler

# Restart a specific service
docker-compose restart airflow-scheduler

# Execute bash in Airflow container
docker exec -it airflow-webserver bash

# Execute bash in PostgreSQL container
docker exec -it postgres18 bash
```

## License

This is example code for educational purposes.
