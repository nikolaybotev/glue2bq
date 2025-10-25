#!/bin/bash

# Script to create Iceberg table and populate with sample data
# This script uses AWS CLI and assumes proper credentials are configured

set -e

# Configuration
BUCKET_NAME="${1:-glue2bq-dev-data-bucket}"
AWS_REGION="${2:-us-east-1}"
TABLE_NAME="sample_iceberg_table"

echo "Creating Iceberg table structure in S3 bucket: $BUCKET_NAME"

# Create directory structure for Iceberg table
aws s3api put-object --bucket "$BUCKET_NAME" --key "iceberg/$TABLE_NAME/metadata/" --region "$AWS_REGION" || true
aws s3api put-object --bucket "$BUCKET_NAME" --key "iceberg/$TABLE_NAME/data/" --region "$AWS_REGION" || true

# Create a simple Iceberg table metadata file
cat > /tmp/metadata.json << EOF
{
  "format-version": 2,
  "table-uuid": "12345678-1234-1234-1234-123456789012",
  "location": "s3://$BUCKET_NAME/iceberg/$TABLE_NAME/",
  "last-updated-ms": $(date +%s)000,
  "last-column-id": 3,
  "schema": {
    "type": "struct",
    "schema-id": 0,
    "fields": [
      {
        "id": 1,
        "name": "id",
        "required": true,
        "type": "long"
      },
      {
        "id": 2,
        "name": "name",
        "required": true,
        "type": "string"
      },
      {
        "id": 3,
        "name": "value",
        "required": true,
        "type": "double"
      }
    ]
  },
  "current-schema-id": 0,
  "schemas": [
    {
      "type": "struct",
      "schema-id": 0,
      "fields": [
        {
          "id": 1,
          "name": "id",
          "required": true,
          "type": "long"
        },
        {
          "id": 2,
          "name": "name",
          "required": true,
          "type": "string"
        },
        {
          "id": 3,
          "name": "value",
          "required": true,
          "type": "double"
        }
      ]
    }
  ],
  "partition-spec": [],
  "default-spec-id": 0,
  "partition-specs": [
    {
      "spec-id": 0,
      "fields": []
    }
  ],
  "last-partition-id": 999,
  "default-sort-order-id": 0,
  "sort-orders": [
    {
      "order-id": 0,
      "fields": []
    }
  ],
  "properties": {
    "owner": "terraform",
    "write.metadata.metrics.default": "truncate(16)",
    "write.metadata.metrics.column.id": "truncate(16)",
    "write.metadata.metrics.column.name": "truncate(16)",
    "write.metadata.metrics.column.value": "truncate(16)"
  },
  "current-snapshot-id": -1,
  "refs": {
    "main": {
      "snapshot-id": -1,
      "type": "branch"
    }
  },
  "snapshots": [],
  "snapshot-log": [],
  "metadata-log": []
}
EOF

# Upload metadata file
aws s3 cp /tmp/metadata.json "s3://$BUCKET_NAME/iceberg/$TABLE_NAME/metadata/v1.metadata.json" --region "$AWS_REGION"

# Create sample data file (Parquet format)
cat > /tmp/sample_data.parquet << EOF
# This is a placeholder for Parquet data
# In a real implementation, you would use a tool like Apache Arrow or pandas
# to create actual Parquet files with the sample data
EOF

# Create a simple CSV file as sample data instead
cat > /tmp/sample_data.csv << EOF
id,name,value
1,"Sample Record 1",10.5
2,"Sample Record 2",20.3
3,"Sample Record 3",15.7
4,"Sample Record 4",8.9
5,"Sample Record 5",12.1
EOF

# Upload sample data
aws s3 cp /tmp/sample_data.csv "s3://$BUCKET_NAME/iceberg/$TABLE_NAME/data/sample_data.csv" --region "$AWS_REGION"

echo "Iceberg table structure created successfully!"
echo "Metadata location: s3://$BUCKET_NAME/iceberg/$TABLE_NAME/metadata/"
echo "Data location: s3://$BUCKET_NAME/iceberg/$TABLE_NAME/data/"

# Clean up temporary files
rm -f /tmp/metadata.json /tmp/sample_data.parquet /tmp/sample_data.csv
