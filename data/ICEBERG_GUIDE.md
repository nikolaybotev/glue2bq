# Creating Iceberg Tables with Date Partitioning

This guide provides multiple approaches to create a small Iceberg dataset in Parquet format partitioned by date, ordered from easiest to most comprehensive.

## Quick Start

```bash
# Run the setup script
./setup_iceberg.sh

# Create the table
./quick_create_iceberg.sh
```

## Available Approaches

### 1. 🎯 AWS Glue Console (Easiest)

**Best for**: One-off table creation, testing, or when you prefer a GUI.

**Steps**:
1. Go to AWS Glue Console → Data Catalog → Tables
2. Click "Add table"
3. Fill in table details:
   - **Database**: Select your Glue database
   - **Table name**: `sample_iceberg_table`
   - **Table type**: `Iceberg`
   - **Location**: `s3://your-bucket/iceberg/sample_iceberg_table/`
4. Define schema:
   ```
   id (bigint)
   name (string)
   value (double)
   category (string)
   date (date)
   ```
5. Set partitioning: `date`
6. Create sample Parquet files and upload to S3

**Pros**: No coding required, immediate visual feedback
**Cons**: Manual process, not repeatable

### 2. 🐍 PyIceberg Script (Simple)

**Best for**: Quick automation, small datasets, when you have catalog access.

```bash
python3 create_iceberg_simple.py your-bucket-name us-east-1 sample_iceberg_table
```

**What it does**:
- Generates 1000 sample records with random dates
- Creates Parquet files with date partitioning structure
- Attempts to create Iceberg table using PyIceberg
- Falls back to creating partitioned Parquet files if catalog is unavailable

**Requirements**:
```bash
pip install pyiceberg pandas pyarrow
```

**Pros**: Lightweight, good for testing
**Cons**: Requires proper Iceberg catalog setup

### 3. ⚡ Apache Spark (Recommended)

**Best for**: Production use, large datasets, complex transformations.

```bash
python3 create_iceberg_spark.py your-bucket-name us-east-1 sample_iceberg_table
```

**What it does**:
- Creates Spark session with Iceberg extensions
- Generates sample data with date partitioning
- Creates Iceberg table with proper schema and partitioning
- Inserts data and shows results

**Requirements**:
- Apache Spark with Iceberg runtime JAR
- Iceberg Spark extensions

**Setup Spark with Iceberg**:
```bash
# Download Spark
wget https://archive.apache.org/dist/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
export SPARK_HOME=$(pwd)/spark-3.5.0-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin

# Download Iceberg runtime JAR
wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.4.2/iceberg-spark-runtime-3.5_2.12-1.4.2.jar
```

**Pros**: Most reliable, handles complex scenarios, production-ready
**Cons**: Requires Spark setup

### 4. 🔧 AWS Glue ETL Job

**Best for**: Production pipelines, automated data processing.

**Steps**:
1. Create Glue ETL job
2. Use Iceberg connector
3. Define schema and partitioning
4. Schedule or trigger as needed

**Pros**: Fully managed, scalable, integrates with existing Glue infrastructure
**Cons**: More complex setup, requires Glue job configuration

## Sample Data Structure

All approaches create data with this structure:

```python
{
    'id': 1,                    # Unique identifier
    'name': 'Record_1',         # Sample name
    'value': 85.42,             # Random decimal value
    'category': 'A',             # Random category (A, B, C, D)
    'date': '2024-01-15'         # Random date (partitioned field)
}
```

## Partitioning Strategy

The table is partitioned by `date` field, which means:
- Data is physically organized by date
- Queries filtering by date are much faster
- Storage is optimized for time-series data
- Each partition contains one day's worth of data

## File Structure

```
s3://your-bucket/iceberg/sample_iceberg_table/
├── metadata/
│   ├── v1.metadata.json
│   └── snap-*.avro
├── data/
│   ├── date=2024-01-01/
│   │   └── data.parquet
│   ├── date=2024-01-02/
│   │   └── data.parquet
│   └── ...
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify S3 bucket access
   aws s3 ls s3://your-bucket/
   ```

2. **PyIceberg Catalog Issues**
   - PyIceberg requires a proper Iceberg catalog
   - Consider using Spark approach instead
   - Or use AWS Glue console for manual creation

3. **Spark Setup Issues**
   - Ensure Spark is properly installed
   - Download Iceberg runtime JAR
   - Set correct environment variables

4. **Glue Database Issues**
   - Verify Glue database exists
   - Check database permissions
   - Ensure KMS key access

### Verification

After creating the table, verify it works:

```python
# Using PyIceberg
from pyiceberg.catalog import load_catalog
catalog = load_catalog("glue_catalog")
table = catalog.load_table("database.sample_iceberg_table")
print(table.scan().to_pandas().head())

# Using Spark
spark.sql("SELECT * FROM database.sample_iceberg_table LIMIT 10").show()
```

## Next Steps

1. **Query the data**: Use BigQuery Omni to query the Iceberg table
2. **Add more data**: Use the same scripts to append more records
3. **Set up monitoring**: Monitor table size and query performance
4. **Optimize**: Consider additional partitioning strategies for larger datasets

## Cost Considerations

- **S3 Storage**: ~$0.023 per GB per month
- **Glue Catalog**: $1 per 100,000 requests
- **BigQuery Omni**: $5 per TB scanned
- **Storage Transfer**: $0.04 per GB transferred

Monitor usage in AWS and GCP consoles to track costs.
