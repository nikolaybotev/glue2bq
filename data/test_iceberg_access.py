#!/usr/bin/env python3
"""
Test script to verify BigQuery Omni can access the new Iceberg table.
"""

import sys
from google.cloud import bigquery
from google.cloud.exceptions import NotFound, BadRequest

def test_iceberg_table_access(project_id, dataset_id, table_name):
    """Test if the Iceberg table is accessible via BigQuery Omni"""
    
    client = bigquery.Client()
    
    # Construct the external table reference
    external_table_id = f"{project_id}.{dataset_id}.{table_name}"
    
    print(f"🔍 Testing Iceberg table access: {external_table_id}")
    
    try:
        # Try a simple count query first
        count_query = f"""
        SELECT COUNT(*) as total_records
        FROM `{external_table_id}`
        """
        
        print(f"📊 Running count query...")
        query_job = client.query(count_query)
        results = query_job.result()
        
        for row in results:
            print(f"✅ Count query successful!")
            print(f"   Total records: {row.total_records}")
        
        # Try a more complex query with date filtering
        date_query = f"""
        SELECT 
            date,
            COUNT(*) as records_per_date,
            AVG(value) as avg_value
        FROM `{external_table_id}`
        WHERE date >= '2024-01-01' AND date <= '2024-01-07'
        GROUP BY date
        ORDER BY date
        LIMIT 10
        """
        
        print(f"\n📅 Running date-filtered query...")
        query_job = client.query(date_query)
        results = query_job.result()
        
        print(f"✅ Date query successful!")
        print(f"   Results:")
        for row in results:
            print(f"     {row.date}: {row.records_per_date} records, avg value: {row.avg_value:.2f}")
        
        # Try the original query that was failing
        original_query = f"""
        SELECT * FROM `{external_table_id}` LIMIT 10
        """
        
        print(f"\n🔍 Running original query (SELECT * LIMIT 10)...")
        query_job = client.query(original_query)
        results = query_job.result()
        
        print(f"✅ Original query successful!")
        print(f"   Sample data:")
        for i, row in enumerate(results):
            if i >= 5:  # Show only first 5 rows
                break
            print(f"     Row {i+1}: id={row.id}, name={row.name}, value={row.value}, category={row.category}, date={row.date}")
        
        return True
        
    except NotFound as e:
        print(f"❌ Table not found: {str(e)}")
        return False
        
    except BadRequest as e:
        print(f"❌ Bad request: {str(e)}")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def main():
    if len(sys.argv) != 4:
        print("Usage: python test_iceberg_access.py <gcp_project_id> <dataset_id> <table_name>")
        print("Example: python test_iceberg_access.py my-project glue2bq_dev_external_dataset sample_iceberg_table_v2")
        sys.exit(1)
    
    project_id = sys.argv[1]
    dataset_id = sys.argv[2]
    table_name = sys.argv[3]
    
    print("🧪 Testing Iceberg Table Access via BigQuery Omni")
    print("=" * 60)
    
    success = test_iceberg_table_access(project_id, dataset_id, table_name)
    
    if success:
        print(f"\n🎉 SUCCESS! The Iceberg table is working with BigQuery Omni!")
        print(f"\n✅ The metadata issue has been resolved!")
        print(f"\nYou can now run queries like:")
        print(f'SELECT * FROM "AwsDataCatalog"."glue2bq-dev_database"."{table_name}" LIMIT 10;')
    else:
        print(f"\n❌ The table is still not accessible.")
        print(f"\nTroubleshooting steps:")
        print(f"1. Check BigQuery Omni connection status")
        print(f"2. Verify IAM permissions")
        print(f"3. Ensure the external dataset is properly configured")
        print(f"4. Check that the Glue table exists and metadata is accessible")

if __name__ == "__main__":
    main()
