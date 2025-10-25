#!/usr/bin/env python3
"""
Create Iceberg table using AWS Glue API directly.
This bypasses the need for a separate Iceberg catalog server.
"""

import boto3
import json
import sys
from datetime import datetime, timedelta
import random
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import os

def get_glue_client(aws_region):
    """Create AWS Glue client"""
    return boto3.client('glue', region_name=aws_region)

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
            'date': record_date.strftime('%Y-%m-%d')
        })
    
    return pd.DataFrame(data)

def create_parquet_files_with_partitioning(df, table_name, bucket_name, aws_region):
    """Create Parquet files with date partitioning structure"""
    
    # Group data by date
    grouped = df.groupby('date')
    
    print("Creating Parquet files with date partitioning...")
    
    local_path = f"/tmp/{table_name}"
    os.makedirs(local_path, exist_ok=True)
    
    for date, group_df in grouped:
        # Convert to PyArrow table
        table = pa.Table.from_pandas(group_df)
        
        # Create partition directory structure
        partition_path = f"{local_path}/date={date}"
        os.makedirs(partition_path, exist_ok=True)
        
        # Write Parquet file
        parquet_file = f"{partition_path}/data.parquet"
        pq.write_table(table, parquet_file)
        
        print(f"Created: {parquet_file} with {len(group_df)} records")
    
    print(f"\nParquet files created in {local_path}/")
    
    # Upload to S3
    print("Uploading to S3...")
    os.system(f"aws s3 sync {local_path}/ s3://{bucket_name}/iceberg/{table_name}/ --region {aws_region}")
    
    print(f"✅ Data uploaded to s3://{bucket_name}/iceberg/{table_name}/")
    
    return local_path

def create_glue_iceberg_table(glue_client, database_name, table_name, bucket_name):
    """Create Iceberg table in AWS Glue"""
    
    table_input = {
        'Name': table_name,
        'Description': 'Sample Iceberg table with date partitioning',
        'TableType': 'EXTERNAL_TABLE',
        'Parameters': {
            'table_type': 'ICEBERG',
            'metadata_location': f's3://{bucket_name}/iceberg/{table_name}/metadata/',
            'write.data.path': f's3://{bucket_name}/iceberg/{table_name}/data/',
            'write.metadata.path': f's3://{bucket_name}/iceberg/{table_name}/metadata/',
            'write.format.default': 'parquet',
            'write.parquet.compression-codec': 'snappy'
        },
        'StorageDescriptor': {
            'Columns': [
                {'Name': 'id', 'Type': 'bigint'},
                {'Name': 'name', 'Type': 'string'},
                {'Name': 'value', 'Type': 'double'},
                {'Name': 'category', 'Type': 'string'},
                {'Name': 'date', 'Type': 'date'}
            ],
            'Location': f's3://{bucket_name}/iceberg/{table_name}/',
            'InputFormat': 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat',
            'OutputFormat': 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat',
            'SerdeInfo': {
                'SerializationLibrary': 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
            }
        },
        'PartitionKeys': [
            {'Name': 'date', 'Type': 'date'}
        ]
    }
    
    try:
        # Check if table already exists
        try:
            glue_client.get_table(DatabaseName=database_name, Name=table_name)
            print(f"Table {table_name} already exists. Updating...")
            glue_client.update_table(DatabaseName=database_name, TableInput=table_input)
        except glue_client.exceptions.EntityNotFoundException:
            print(f"Creating new table {table_name}...")
            glue_client.create_table(DatabaseName=database_name, TableInput=table_input)
        
        print(f"✅ Successfully created/updated Iceberg table: {database_name}.{table_name}")
        return True
        
    except Exception as e:
        print(f"❌ Error creating Glue table: {str(e)}")
        return False

def main():
    if len(sys.argv) != 4:
        print("Usage: python create_glue_iceberg.py <bucket_name> <aws_region> <table_name>")
        print("Example: python create_glue_iceberg.py glue2bq-dev-data-bucket us-east-1 sample_iceberg_table")
        sys.exit(1)
    
    bucket_name = sys.argv[1]
    aws_region = sys.argv[2]
    table_name = sys.argv[3]
    database_name = "glue2bq-dev_database"  # This should match your Glue database name
    
    print(f"Creating Iceberg table '{table_name}' in database '{database_name}'")
    print(f"Using bucket: {bucket_name} in region: {aws_region}")
    
    # Create Glue client
    glue_client = get_glue_client(aws_region)
    
    try:
        # Generate sample data
        print("Generating sample data...")
        df = create_sample_data(num_records=1000)
        print(f"Generated {len(df)} records")
        
        # Create Parquet files with partitioning
        print("Creating Parquet files...")
        local_path = create_parquet_files_with_partitioning(df, table_name, bucket_name, aws_region)
        
        # Create Glue table
        print("Creating Glue Iceberg table...")
        success = create_glue_iceberg_table(glue_client, database_name, table_name, bucket_name)
        
        if success:
            print(f"\n🎉 Successfully created Iceberg table!")
            print(f"Table: {database_name}.{table_name}")
            print(f"Location: s3://{bucket_name}/iceberg/{table_name}/")
            print(f"Partitioned by: date")
            print(f"Format: Parquet")
            
            # Show sample data
            print(f"\nSample data:")
            print(df.head(10).to_string(index=False))
            
            print(f"\nNext steps:")
            print(f"1. Query the table in BigQuery Omni")
            print(f"2. Add more data using the same approach")
            print(f"3. Monitor table usage in AWS Glue console")
        else:
            print("❌ Failed to create Glue table")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)
    
    finally:
        # Clean up local files
        if 'local_path' in locals():
            os.system(f"rm -rf {local_path}")

if __name__ == "__main__":
    main()
