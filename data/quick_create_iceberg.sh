#!/bin/bash
# Quick script to create Iceberg table

BUCKET_NAME="glue2bq-dev-data-bucket"
AWS_REGION="us-east-1"
TABLE_NAME="sample_iceberg_table"

echo "Creating Iceberg table: $TABLE_NAME"
echo "Bucket: $BUCKET_NAME"
echo "Region: $AWS_REGION"
echo ""

# Try PyIceberg approach first
echo "🔄 Attempting PyIceberg approach..."
python3 create_iceberg_simple.py "$BUCKET_NAME" "$AWS_REGION" "$TABLE_NAME"

if [ $? -ne 0 ]; then
    echo ""
    echo "🔄 PyIceberg failed, trying Spark approach..."
    if command -v spark-submit >/dev/null 2>&1; then
        python3 create_iceberg_spark.py "$BUCKET_NAME" "$AWS_REGION" "$TABLE_NAME"
    else
        echo "❌ Spark not available. Please use AWS Glue console instead."
        echo ""
        echo "📋 Manual Steps:"
        echo "1. Go to AWS Glue Console"
        echo "2. Create new table in your database"
        echo "3. Set table type to 'Iceberg'"
        echo "4. Define schema with date partitioning"
        echo "5. Upload sample Parquet files to S3"
    fi
fi
