#!/bin/bash

# Setup script for creating Iceberg tables with date partitioning
# This script installs dependencies and provides multiple approaches

set -e

echo "🚀 Iceberg Table Creation Setup"
echo "================================"

# Check if we're in the right directory
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Get configuration from terraform outputs or use defaults
BUCKET_NAME="${1:-$(terraform output -raw s3_bucket_name 2>/dev/null || echo 'glue2bq-dev-data-bucket')}"
AWS_REGION="${2:-$(terraform output -raw aws_region 2>/dev/null || echo 'us-east-1')}"
TABLE_NAME="${3:-sample_iceberg_table}"

echo "Configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo "  Table: $TABLE_NAME"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Python dependencies
echo "📦 Installing Python dependencies..."
if command_exists pip3; then
    pip3 install pyiceberg pandas pyarrow
elif command_exists pip; then
    pip install pyiceberg pandas pyarrow
else
    echo "❌ Error: pip not found. Please install Python and pip first."
    exit 1
fi

# Check if Spark is available
if command_exists spark-submit; then
    echo "✅ Spark found: $(spark-submit --version 2>&1 | head -1)"
    SPARK_AVAILABLE=true
else
    echo "⚠️  Spark not found. You can still use the PyIceberg approach."
    echo "   To install Spark:"
    echo "   1. Download from https://spark.apache.org/downloads.html"
    echo "   2. Extract and add to PATH"
    echo "   3. Install Iceberg Spark runtime JAR"
    SPARK_AVAILABLE=false
fi

echo ""
echo "🎯 Available Approaches:"
echo "======================="

if [ "$SPARK_AVAILABLE" = true ]; then
    echo "1. ✅ Spark + Iceberg (RECOMMENDED)"
    echo "   - Most reliable and feature-complete"
    echo "   - Handles partitioning automatically"
    echo "   - Command: python3 create_iceberg_spark.py $BUCKET_NAME $AWS_REGION $TABLE_NAME"
    echo ""
fi

echo "2. ✅ PyIceberg (Simple)"
echo "   - Easier setup, but requires catalog configuration"
echo "   - Command: python3 create_iceberg_simple.py $BUCKET_NAME $AWS_REGION $TABLE_NAME"
echo ""

echo "3. ✅ AWS Glue Console (Manual)"
echo "   - Use AWS Glue console to create Iceberg table"
echo "   - Upload Parquet files manually"
echo "   - Most straightforward for one-off creation"
echo ""

echo "4. ✅ AWS Glue ETL Job"
echo "   - Create Glue ETL job with Iceberg support"
echo "   - Automated and repeatable"
echo ""

# Create a quick start script
cat > quick_create_iceberg.sh << EOF
#!/bin/bash
# Quick script to create Iceberg table

BUCKET_NAME="$BUCKET_NAME"
AWS_REGION="$AWS_REGION"
TABLE_NAME="$TABLE_NAME"

echo "Creating Iceberg table: \$TABLE_NAME"
echo "Bucket: \$BUCKET_NAME"
echo "Region: \$AWS_REGION"
echo ""

# Try PyIceberg approach first
echo "🔄 Attempting PyIceberg approach..."
python3 create_iceberg_simple.py "\$BUCKET_NAME" "\$AWS_REGION" "\$TABLE_NAME"

if [ \$? -ne 0 ]; then
    echo ""
    echo "🔄 PyIceberg failed, trying Spark approach..."
    if command -v spark-submit >/dev/null 2>&1; then
        python3 create_iceberg_spark.py "\$BUCKET_NAME" "\$AWS_REGION" "\$TABLE_NAME"
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
EOF

chmod +x quick_create_iceberg.sh

echo "✅ Setup complete!"
echo ""
echo "🚀 Quick Start:"
echo "==============="
echo "Run: ./quick_create_iceberg.sh"
echo ""
echo "Or choose a specific approach:"
if [ "$SPARK_AVAILABLE" = true ]; then
    echo "  Spark: python3 create_iceberg_spark.py $BUCKET_NAME $AWS_REGION $TABLE_NAME"
fi
echo "  PyIceberg: python3 create_iceberg_simple.py $BUCKET_NAME $AWS_REGION $TABLE_NAME"
echo ""
echo "📚 For more details, see the individual script files."
