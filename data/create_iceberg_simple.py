#!/usr/bin/env python3
"""
Simplified script to create a small Iceberg dataset in Parquet format partitioned by date using PyIceberg.
This is easier to set up than Spark but requires a proper Iceberg catalog.
"""

import sys
import os
from datetime import datetime, timedelta
import random
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from pyiceberg.catalog import load_catalog
from pyiceberg.schema import Schema
from pyiceberg.types import (
    NestedField, StringType, LongType, DoubleType, DateType
)
from pyiceberg.partitioning import PartitionSpec, PartitionField
from pyiceberg.transforms import IdentityTransform

def create_sample_data(num_records=1000):
    """Create sample data with date partitioning"""
    data = []
    base_date = datetime(2024, 1, 1)
    
    for i in range(num_records):
        # Generate random date within the last 30 days
        random_days = random.randint(0, 30)
        record_date = base_date + timedelta(days=random_days)
        
        data.append({
            'id': i + 1,
            'name': f'Record_{i + 1}',
            'value': round(random.uniform(10.0, 100.0), 2),
            'category': random.choice(['A', 'B', 'C', 'D']),
            'date': record_date.date()
        })
    
    return pd.DataFrame(data)

def create_iceberg_table_pyiceberg(bucket_name, aws_region, table_name, database_name):
    """Create Iceberg table using PyIceberg"""
    
    # Define the schema
    schema = Schema(
        NestedField(1, "id", LongType(), required=True),
        NestedField(2, "name", StringType(), required=True),
        NestedField(3, "value", DoubleType(), required=True),
        NestedField(4, "category", StringType(), required=True),
        NestedField(5, "date", DateType(), required=True),
    )
    
    # Define partitioning by date
    partition_spec = PartitionSpec(
        PartitionField(source_id=5, field_id=1000, transform=IdentityTransform(), name="date")
    )
    
    # Create catalog configuration
    catalog_config = {
        'type': 'rest',
        'uri': 'http://localhost:8181',  # You'll need to set up an Iceberg REST catalog
        'warehouse': f's3://{bucket_name}/iceberg/',
        's3': {
            'region': aws_region
        }
    }
    
    try:
        # Load catalog
        catalog = load_catalog("local", **catalog_config)
        
        # Create namespace (database)
        try:
            catalog.create_namespace(database_name)
            print(f"Created namespace: {database_name}")
        except Exception:
            print(f"Namespace {database_name} already exists")
        
        # Create table
        table = catalog.create_table(
            f"{database_name}.{table_name}",
            schema=schema,
            partition_spec=partition_spec,
            location=f"s3://{bucket_name}/iceberg/{database_name}/{table_name}/"
        )
        
        print(f"Created Iceberg table: {database_name}.{table_name}")
        return table
        
    except Exception as e:
        print(f"Error creating table with PyIceberg: {e}")
        print("Note: PyIceberg requires a proper Iceberg catalog setup.")
        return None

def create_parquet_files_with_partitioning(df, bucket_name, table_name, aws_region):
    """Create Parquet files with date partitioning structure"""
    
    # Group data by date
    grouped = df.groupby('date')
    
    print("Creating Parquet files with date partitioning...")
    
    for date, group_df in grouped:
        # Convert to PyArrow table
        table = pa.Table.from_pandas(group_df)
        
        # Create partition directory structure
        partition_path = f"/tmp/{table_name}/date={date.strftime('%Y-%m-%d')}"
        os.makedirs(partition_path, exist_ok=True)
        
        # Write Parquet file
        parquet_file = f"{partition_path}/data.parquet"
        pq.write_table(table, parquet_file)
        
        print(f"Created: {parquet_file} with {len(group_df)} records")
    
    print(f"Parquet files created in /tmp/{table_name}/")
    print("You can upload these to S3 manually or use AWS CLI:")
    print(f"aws s3 sync /tmp/{table_name}/ s3://{bucket_name}/iceberg/{table_name}/ --region {aws_region}")

def main():
    if len(sys.argv) != 4:
        print("Usage: python create_iceberg_simple.py <bucket_name> <aws_region> <table_name>")
        print("Example: python create_iceberg_simple.py glue2bq-dev-data-bucket us-east-1 sample_iceberg_table")
        sys.exit(1)
    
    bucket_name = sys.argv[1]
    aws_region = sys.argv[2]
    table_name = sys.argv[3]
    database_name = "glue2bq_dev_database"
    
    print(f"Creating Iceberg dataset '{table_name}' in bucket '{bucket_name}'")
    
    # Generate sample data
    print("Generating sample data...")
    df = create_sample_data(num_records=1000)
    print(f"Generated {len(df)} records")
    
    # Try PyIceberg approach first
    print("\nAttempting to create table with PyIceberg...")
    table = create_iceberg_table_pyiceberg(bucket_name, aws_region, table_name, database_name)
    
    if table is None:
        print("\nPyIceberg approach failed. Creating Parquet files with partitioning structure instead...")
        create_parquet_files_with_partitioning(df, bucket_name, table_name, aws_region)
        
        print("\n" + "="*60)
        print("ALTERNATIVE APPROACH: Use AWS Glue directly")
        print("="*60)
        print("Since PyIceberg requires a catalog setup, here's a simpler approach:")
        print("1. Use AWS Glue console to create an Iceberg table")
        print("2. Upload the Parquet files created above to S3")
        print("3. Use AWS Glue to register the table")
        print("\nOr use the Spark approach (create_iceberg_spark.py) which is more reliable.")
    else:
        print("✅ Successfully created Iceberg table with PyIceberg!")

if __name__ == "__main__":
    main()
