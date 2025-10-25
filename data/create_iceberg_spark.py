#!/usr/bin/env python3
"""
Script to create a small Iceberg dataset in Parquet format partitioned by date using Spark.
This is the easiest and most reliable method for creating Iceberg tables.
"""

import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_date, date_add, rand
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType
import random
from datetime import datetime, timedelta

def create_spark_session(bucket_name, aws_region):
    """Create Spark session with Iceberg support"""
    return SparkSession.builder \
        .appName("CreateIcebergTable") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog") \
        .config("spark.sql.catalog.glue_catalog.warehouse", f"s3://{bucket_name}/iceberg/") \
        .config("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO") \
        .config("spark.sql.catalog.glue_catalog.s3.region", aws_region) \
        .config("spark.sql.catalog.glue_catalog.lock-impl", "org.apache.iceberg.aws.glue.DynamoDbLockManager") \
        .config("spark.sql.catalog.glue_catalog.lock.table", "iceberg-lock-table") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .getOrCreate()

def generate_sample_data(spark, num_records=1000):
    """Generate sample data with date partitioning"""
    
    # Create sample data
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
    
    # Create DataFrame
    df = spark.createDataFrame(data)
    
    # Convert date string to date type
    df = df.withColumn("date", col("date").cast(DateType()))
    
    return df

def create_iceberg_table(spark, database_name, table_name, df):
    """Create Iceberg table with date partitioning"""
    
    # Create the table with date partitioning
    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {database_name}.{table_name} (
            id BIGINT,
            name STRING,
            value DOUBLE,
            category STRING,
            date DATE
        ) USING iceberg
        PARTITIONED BY (date)
        TBLPROPERTIES (
            'write.format.default' = 'parquet',
            'write.parquet.compression-codec' = 'snappy'
        )
    """)
    
    print(f"Created Iceberg table: {database_name}.{table_name}")
    
    # Insert data into the table
    df.writeTo(f"{database_name}.{table_name}").append()
    
    print(f"Inserted {df.count()} records into the table")

def main():
    if len(sys.argv) != 4:
        print("Usage: python create_iceberg_spark.py <bucket_name> <aws_region> <table_name>")
        print("Example: python create_iceberg_spark.py glue2bq-dev-data-bucket us-east-1 sample_iceberg_table")
        sys.exit(1)
    
    bucket_name = sys.argv[1]
    aws_region = sys.argv[2]
    table_name = sys.argv[3]
    database_name = "glue2bq_dev_database"  # This should match your Glue database name
    
    print(f"Creating Iceberg table '{table_name}' in database '{database_name}'")
    print(f"Using bucket: {bucket_name} in region: {aws_region}")
    
    # Create Spark session
    spark = create_spark_session(bucket_name, aws_region)
    
    try:
        # Generate sample data
        print("Generating sample data...")
        df = generate_sample_data(spark, num_records=1000)
        
        # Create Iceberg table
        print("Creating Iceberg table...")
        create_iceberg_table(spark, database_name, table_name, df)
        
        # Show some sample data
        print("\nSample data from the table:")
        spark.sql(f"SELECT * FROM {database_name}.{table_name} ORDER BY date DESC LIMIT 10").show()
        
        # Show partition information
        print("\nPartition information:")
        spark.sql(f"SHOW PARTITIONS {database_name}.{table_name}").show()
        
        print(f"\n✅ Successfully created Iceberg table '{table_name}' with date partitioning!")
        print(f"Table location: s3://{bucket_name}/iceberg/{database_name}/{table_name}/")
        
    except Exception as e:
        print(f"❌ Error creating Iceberg table: {str(e)}")
        sys.exit(1)
    
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
