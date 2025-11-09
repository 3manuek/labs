.PHONY: help start stop restart status logs logs-airflow logs-postgres logs-scheduler \
	shell-airflow shell-postgres db-connect setup-connection test-db clean clean-all \
	up down init check-health wait-for-services trigger-dag list-dags

.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)  Apache Airflow + PostgreSQL 18 Laboratory$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  1. $(CYAN)make start$(NC)         - Start all services"
	@echo "  2. $(CYAN)make wait-for-services$(NC) - Wait for services to be ready"
	@echo "  3. $(CYAN)make setup-connection$(NC) - Configure Airflow connection"
	@echo "  4. $(CYAN)make check-health$(NC) - Verify everything is working"
	@echo ""

##@ Service Management

start: ## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "$(YELLOW)Waiting for services to initialize...$(NC)"
	@sleep 5
	@$(MAKE) status

stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	docker-compose stop
	@echo "$(GREEN)Services stopped!$(NC)"

down: ## Stop and remove all containers
	@echo "$(YELLOW)Stopping and removing containers...$(NC)"
	docker-compose down
	@echo "$(GREEN)Containers removed!$(NC)"

restart: ## Restart all services
	@echo "$(YELLOW)Restarting services...$(NC)"
	docker-compose restart
	@echo "$(GREEN)Services restarted!$(NC)"

up: start ## Alias for start

##@ Status and Monitoring

status: ## Show status of all services
	@echo "$(CYAN)Service Status:$(NC)"
	@docker-compose ps

check-health: ## Check health of all services
	@echo "$(CYAN)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL Status:$(NC)"
	@docker-compose exec -T postgres pg_isready -U airflow && echo "$(GREEN)✓ PostgreSQL is ready$(NC)" || echo "$(RED)✗ PostgreSQL is not ready$(NC)"
	@echo ""
	@echo "$(YELLOW)Airflow Webserver Status:$(NC)"
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/health | grep -q "200" && echo "$(GREEN)✓ Airflow webserver is healthy$(NC)" || echo "$(RED)✗ Airflow webserver is not healthy$(NC)"
	@echo ""
	@echo "$(YELLOW)Airflow Scheduler Status:$(NC)"
	@docker-compose exec -T airflow-scheduler airflow jobs check --job-type SchedulerJob --hostname "$$(docker-compose exec -T airflow-scheduler hostname)" && echo "$(GREEN)✓ Scheduler is running$(NC)" || echo "$(YELLOW)⚠ Scheduler status unknown$(NC)"

wait-for-services: ## Wait for all services to be healthy
	@echo "$(YELLOW)Waiting for PostgreSQL to be ready...$(NC)"
	@timeout=60; \
	while ! docker-compose exec -T postgres pg_isready -U airflow > /dev/null 2>&1; do \
		sleep 2; \
		timeout=$$((timeout-2)); \
		if [ $$timeout -le 0 ]; then \
			echo "$(RED)Timeout waiting for PostgreSQL$(NC)"; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)✓ PostgreSQL is ready$(NC)"
	@echo ""
	@echo "$(YELLOW)Waiting for Airflow webserver to be ready...$(NC)"
	@timeout=120; \
	while ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/health 2>/dev/null | grep -q "200"; do \
		sleep 5; \
		timeout=$$((timeout-5)); \
		if [ $$timeout -le 0 ]; then \
			echo "$(RED)Timeout waiting for Airflow webserver$(NC)"; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)✓ Airflow webserver is ready$(NC)"
	@echo ""
	@echo "$(GREEN)All services are ready!$(NC)"

##@ Logs

logs: ## Show logs from all services
	docker-compose logs -f

logs-airflow: ## Show Airflow webserver logs
	docker-compose logs -f airflow-webserver

logs-scheduler: ## Show Airflow scheduler logs
	docker-compose logs -f airflow-scheduler

logs-postgres: ## Show PostgreSQL logs
	docker-compose logs -f postgres

##@ Shell Access

shell-airflow: ## Open bash shell in Airflow webserver container
	docker-compose exec airflow-webserver bash

shell-postgres: ## Open bash shell in PostgreSQL container
	docker-compose exec postgres bash

##@ Database Operations

db-connect: ## Connect to sample_data database with psql
	@echo "$(CYAN)Connecting to sample_data database...$(NC)"
	@echo "$(YELLOW)Password: airflow$(NC)"
	docker-compose exec postgres psql -U airflow -d sample_data

db-connect-airflow: ## Connect to Airflow metadata database
	@echo "$(CYAN)Connecting to Airflow metadata database...$(NC)"
	@echo "$(YELLOW)Password: airflow$(NC)"
	docker-compose exec postgres psql -U airflow -d airflow

test-db: ## Test database and show sample data
	@echo "$(CYAN)Testing database connection and showing sample data...$(NC)"
	@echo ""
	@echo "$(YELLOW)Users:$(NC)"
	@docker-compose exec -T postgres psql -U airflow -d sample_data -c "SELECT user_id, username, email FROM users;"
	@echo ""
	@echo "$(YELLOW)Products (first 5):$(NC)"
	@docker-compose exec -T postgres psql -U airflow -d sample_data -c "SELECT product_id, product_name, price, stock_quantity FROM products LIMIT 5;"
	@echo ""
	@echo "$(YELLOW)Orders Summary:$(NC)"
	@docker-compose exec -T postgres psql -U airflow -d sample_data -c "SELECT * FROM order_summary LIMIT 5;"
	@echo ""
	@echo "$(YELLOW)Product Sales (Top 5):$(NC)"
	@docker-compose exec -T postgres psql -U airflow -d sample_data -c "SELECT * FROM product_sales LIMIT 5;"

##@ Airflow Operations

setup-connection: ## Create PostgreSQL connection in Airflow
	@echo "$(CYAN)Setting up PostgreSQL connection in Airflow...$(NC)"
	@docker-compose exec -T airflow-webserver airflow connections delete postgres_sample 2>/dev/null || true
	@docker-compose exec -T airflow-webserver airflow connections add postgres_sample \
		--conn-type postgres \
		--conn-host postgres \
		--conn-schema sample_data \
		--conn-login airflow \
		--conn-password airflow \
		--conn-port 5432
	@echo "$(GREEN)✓ Connection 'postgres_sample' created successfully!$(NC)"

list-dags: ## List all available DAGs
	@echo "$(CYAN)Available DAGs:$(NC)"
	docker-compose exec -T airflow-scheduler airflow dags list

trigger-dag: ## Trigger the example DAG (usage: make trigger-dag DAG=postgres_example_dag)
	@if [ -z "$(DAG)" ]; then \
		echo "$(YELLOW)Triggering postgres_example_dag...$(NC)"; \
		docker-compose exec -T airflow-scheduler airflow dags trigger postgres_example_dag; \
	else \
		echo "$(YELLOW)Triggering $(DAG)...$(NC)"; \
		docker-compose exec -T airflow-scheduler airflow dags trigger $(DAG); \
	fi
	@echo "$(GREEN)DAG triggered! Check the Airflow UI at http://localhost:8081$(NC)"

unpause-dag: ## Unpause the example DAG (usage: make unpause-dag DAG=postgres_example_dag)
	@if [ -z "$(DAG)" ]; then \
		echo "$(YELLOW)Unpausing postgres_example_dag...$(NC)"; \
		docker-compose exec -T airflow-scheduler airflow dags unpause postgres_example_dag; \
	else \
		echo "$(YELLOW)Unpausing $(DAG)...$(NC)"; \
		docker-compose exec -T airflow-scheduler airflow dags unpause $(DAG); \
	fi
	@echo "$(GREEN)DAG unpaused!$(NC)"

list-connections: ## List all Airflow connections
	@echo "$(CYAN)Airflow Connections:$(NC)"
	docker-compose exec -T airflow-webserver airflow connections list

##@ Initialization and Setup

init: start wait-for-services setup-connection check-health ## Complete initialization (start + setup + verify)
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  Setup Complete!$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(CYAN)Access Points:$(NC)"
	@echo "  • Airflow UI: $(YELLOW)http://localhost:8081$(NC)"
	@echo "    Username: $(CYAN)admin$(NC)"
	@echo "    Password: $(CYAN)admin$(NC)"
	@echo ""
	@echo "  • PostgreSQL: $(YELLOW)localhost:5432$(NC)"
	@echo "    User: $(CYAN)airflow$(NC)"
	@echo "    Password: $(CYAN)airflow$(NC)"
	@echo "    Database: $(CYAN)sample_data$(NC)"
	@echo ""
	@echo "$(CYAN)Next Steps:$(NC)"
	@echo "  1. Visit Airflow UI: http://localhost:8081"
	@echo "  2. Find the 'postgres_example_dag' in the DAGs list"
	@echo "  3. Toggle it ON and trigger a manual run"
	@echo "  4. Use '$(CYAN)make test-db$(NC)' to explore the database"
	@echo ""
	@echo "$(CYAN)Useful Commands:$(NC)"
	@echo "  • $(CYAN)make test-db$(NC)       - View sample data"
	@echo "  • $(CYAN)make db-connect$(NC)    - Connect to database"
	@echo "  • $(CYAN)make logs$(NC)          - View all logs"
	@echo "  • $(CYAN)make help$(NC)          - Show all commands"
	@echo ""

##@ Cleanup

clean: down ## Stop and remove containers (keeps volumes)
	@echo "$(GREEN)Cleanup complete. Data volumes preserved.$(NC)"

clean-all: ## Stop and remove everything including volumes (destroys all data)
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Removing everything...$(NC)"; \
		docker-compose down -v; \
		echo "$(GREEN)Complete cleanup done!$(NC)"; \
	else \
		echo "$(YELLOW)Cleanup cancelled.$(NC)"; \
	fi

##@ Testing and Verification

verify: check-health test-db ## Verify installation is working correctly
	@echo ""
	@echo "$(GREEN)✓ Verification complete!$(NC)"

info: ## Show connection information
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)  Connection Information$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Airflow UI:$(NC)"
	@echo "  URL:      http://localhost:8081"
	@echo "  Username: admin"
	@echo "  Password: admin"
	@echo ""
	@echo "$(YELLOW)PostgreSQL (sample_data):$(NC)"
	@echo "  Host:     localhost"
	@echo "  Port:     5432"
	@echo "  User:     airflow"
	@echo "  Password: airflow"
	@echo "  Database: sample_data"
	@echo ""
	@echo "$(YELLOW)Connection String:$(NC)"
	@echo "  postgresql://airflow:airflow@localhost:5432/sample_data"
	@echo ""
