"""
Example Airflow DAG demonstrating PostgreSQL integration.

This DAG performs various operations on the sample_data database:
1. Queries user and order data
2. Calculates daily sales metrics
3. Updates order statuses
4. Generates reports
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}


def fetch_and_process_orders(**context):
    """
    Fetch orders from PostgreSQL and perform some processing.
    """
    pg_hook = PostgresHook(postgres_conn_id='postgres_sample')

    # Query to get pending orders
    query = """
        SELECT o.order_id, u.username, o.total_amount, o.order_date
        FROM orders o
        JOIN users u ON o.user_id = u.user_id
        WHERE o.status = 'pending'
        ORDER BY o.order_date DESC
    """

    records = pg_hook.get_records(query)

    print(f"Found {len(records)} pending orders:")
    for record in records:
        order_id, username, amount, order_date = record
        print(f"  Order {order_id}: {username} - ${amount} on {order_date}")

    # Push the count to XCom for downstream tasks
    context['task_instance'].xcom_push(key='pending_orders_count', value=len(records))

    return len(records)


def calculate_daily_revenue(**context):
    """
    Calculate daily revenue from completed orders.
    """
    pg_hook = PostgresHook(postgres_conn_id='postgres_sample')

    query = """
        SELECT
            DATE(order_date) as order_date,
            COUNT(*) as order_count,
            SUM(total_amount) as daily_revenue
        FROM orders
        WHERE status = 'completed'
        GROUP BY DATE(order_date)
        ORDER BY order_date DESC
        LIMIT 7
    """

    records = pg_hook.get_records(query)

    print("Daily Revenue Summary (Last 7 days):")
    print("-" * 50)
    for record in records:
        date, count, revenue = record
        print(f"  {date}: {count} orders - ${revenue:.2f}")

    return records


def check_low_stock_products(**context):
    """
    Check for products with low stock and log warnings.
    """
    pg_hook = PostgresHook(postgres_conn_id='postgres_sample')

    query = """
        SELECT product_id, product_name, stock_quantity, category
        FROM products
        WHERE stock_quantity < 100
        ORDER BY stock_quantity ASC
    """

    records = pg_hook.get_records(query)

    if records:
        print(f"Warning: {len(records)} products have low stock:")
        for record in records:
            product_id, name, stock, category = record
            print(f"  [{category}] {name} (ID: {product_id}): {stock} units remaining")
    else:
        print("All products have adequate stock levels.")

    return len(records)


with DAG(
    'postgres_example_dag',
    default_args=default_args,
    description='Example DAG with PostgreSQL operations',
    schedule_interval='@daily',
    catchup=False,
    tags=['example', 'postgres'],
) as dag:

    # Task 1: Create a sales report table if it doesn't exist
    create_sales_report_table = PostgresOperator(
        task_id='create_sales_report_table',
        postgres_conn_id='postgres_sample',
        sql="""
            CREATE TABLE IF NOT EXISTS daily_sales_report (
                report_id SERIAL PRIMARY KEY,
                report_date DATE NOT NULL,
                total_orders INTEGER,
                total_revenue DECIMAL(10, 2),
                avg_order_value DECIMAL(10, 2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """
    )

    # Task 2: Insert daily sales metrics
    insert_daily_metrics = PostgresOperator(
        task_id='insert_daily_metrics',
        postgres_conn_id='postgres_sample',
        sql="""
            INSERT INTO daily_sales_report (report_date, total_orders, total_revenue, avg_order_value)
            SELECT
                CURRENT_DATE,
                COUNT(*) as total_orders,
                SUM(total_amount) as total_revenue,
                AVG(total_amount) as avg_order_value
            FROM orders
            WHERE DATE(order_date) = CURRENT_DATE
            ON CONFLICT DO NOTHING;
        """
    )

    # Task 3: Process pending orders
    process_orders_task = PythonOperator(
        task_id='process_pending_orders',
        python_callable=fetch_and_process_orders,
        provide_context=True,
    )

    # Task 4: Calculate daily revenue
    calculate_revenue_task = PythonOperator(
        task_id='calculate_daily_revenue',
        python_callable=calculate_daily_revenue,
        provide_context=True,
    )

    # Task 5: Check low stock
    check_stock_task = PythonOperator(
        task_id='check_low_stock',
        python_callable=check_low_stock_products,
        provide_context=True,
    )

    # Task 6: Update old pending orders to 'processing'
    update_old_pending_orders = PostgresOperator(
        task_id='update_old_pending_orders',
        postgres_conn_id='postgres_sample',
        sql="""
            UPDATE orders
            SET status = 'processing'
            WHERE status = 'pending'
            AND order_date < CURRENT_TIMESTAMP - INTERVAL '7 days';
        """
    )

    # Task 7: Query top selling products
    get_top_products = PostgresOperator(
        task_id='get_top_selling_products',
        postgres_conn_id='postgres_sample',
        sql="""
            SELECT
                p.product_name,
                p.category,
                COUNT(oi.order_item_id) as times_ordered,
                SUM(oi.quantity) as total_quantity,
                SUM(oi.quantity * oi.unit_price) as total_revenue
            FROM products p
            JOIN order_items oi ON p.product_id = oi.product_id
            GROUP BY p.product_id, p.product_name, p.category
            ORDER BY total_revenue DESC
            LIMIT 5;
        """
    )

    # Define task dependencies
    create_sales_report_table >> insert_daily_metrics
    create_sales_report_table >> process_orders_task
    create_sales_report_table >> calculate_revenue_task
    create_sales_report_table >> check_stock_task

    process_orders_task >> update_old_pending_orders
    [calculate_revenue_task, check_stock_task] >> get_top_products
