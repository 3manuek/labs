#!/usr/bin/env python3
import json
from kafka import KafkaConsumer
from clickhouse_driver import Client
import time
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def connect_kafka():
    while True:
        try:
            consumer = KafkaConsumer(
                'postgres.public.users',
                bootstrap_servers='kafka:29092',
                auto_offset_reset='earliest',
                value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                group_id='clickhouse-consumer'
            )
            logger.info("Connected to Kafka")
            return consumer
        except Exception as e:
            logger.error(f"Failed to connect to Kafka: {e}")
            time.sleep(5)

def connect_clickhouse():
    while True:
        try:
            client = Client(host='clickhouse', user='default', password='clickhouse')
            logger.info("Connected to ClickHouse")
            return client
        except Exception as e:
            logger.error(f"Failed to connect to ClickHouse: {e}")
            time.sleep(5)

def process_message(client, message):
    try:
        data = message.value

        # Handle Debezium CDC format
        if 'after' not in data:
            logger.warning(f"Skipping message without 'after' field: {data}")
            return

        record = data['after']
        op = data.get('op', 'c')  # c=create, u=update, d=delete, r=read

        if op == 'd':  # Delete operation
            logger.info(f"Skipping delete operation for id={record.get('id')}")
            return

        # Extract values
        user_id = record.get('id')
        name = record.get('name', '')
        email = record.get('email', '')
        age = record.get('age')
        created_at_micros = record.get('created_at')

        # Convert microseconds to datetime
        created_at = None
        if created_at_micros:
            # Debezium sends microseconds since epoch
            created_at = datetime.fromtimestamp(created_at_micros / 1000000.0)

        # Use ReplacingMergeTree behavior - ClickHouse will handle duplicates
        query = """
            INSERT INTO default.users (id, name, email, age, created_at)
            VALUES
        """

        client.execute(
            query,
            [(user_id, name, email, age, created_at)]
        )

        logger.info(f"Inserted/Updated user id={user_id}, name={name}")

    except Exception as e:
        logger.error(f"Error processing message: {e}", exc_info=True)

def main():
    logger.info("Starting Kafka-ClickHouse consumer...")

    consumer = connect_kafka()
    client = connect_clickhouse()

    logger.info("Consuming messages...")

    for message in consumer:
        process_message(client, message)

if __name__ == "__main__":
    main()
