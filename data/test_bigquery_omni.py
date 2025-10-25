#!/usr/bin/env python3
"""
Test script to verify the Iceberg table is accessible via BigQuery Omni.
This script checks if the table can be queried through the BigQuery Omni connection.
"""

import sys
from google.cloud import bigquery
from google.cloud.exceptions import NotFound, BadRequest
import json

def get_bigquery_client():
    """Create BigQuery client"""
    return bigquery.Client()

def test_table_access(client, project_id, dataset_id, table_name):
    """Test if the table is accessible via BigQuery Omni"""
    
    # Construct the external table reference
    external_table_id = f"{project_id}.{dataset_id}.{table_name}"
    
    print(f"Testing access to external table: {external_table_id}")
    
    try:
        # Try to get table metadata
        table = client.get_table(external_table_id)
        print(f"✅ Table found: {table.full_table_id}")
        print(f"   Description: {table.description}")
        print(f"   Created: {table.created}")
        print(f"   Modified: {table.modified}")
        
        # Try a simple query
        query = f"""
        SELECT COUNT(*) as total_records,
               COUNT(DISTINCT date) as unique_dates,
               MIN(date) as earliest_date,
               MAX(date) as latest_date
        FROM `{external_table_id}`
        """
        
        print(f"\n🔍 Testing query: {query.strip()}")
        
        query_job = client.query(query)
        results = query_job.result()
        
        for row in results:
            print(f"✅ Query successful!")
            print(f"   Total records: {row.total_records}")
            print(f"   Unique dates: {row.unique_dates}")
            print(f"   Date range: {row.earliest_date} to {row.latest_date}")
        
        return True
        
    except NotFound as e:
        print(f"❌ Table not found: {str(e)}")
        print("   This might mean:")
        print("   1. The BigQuery Omni connection is not properly configured")
        print("   2. The external dataset doesn't exist")
        print("   3. The table name is incorrect")
        return False
        
    except BadRequest as e:
        print(f"❌ Bad request: {str(e)}")
        print("   This might indicate a configuration issue with BigQuery Omni")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def list_external_datasets(client, project_id):
    """List all external datasets in the project"""
    
    print(f"\n📋 Listing external datasets in project: {project_id}")
    
    try:
        datasets = list(client.list_datasets(project=project_id))
        
        if not datasets:
            print("   No datasets found")
            return []
        
        external_datasets = []
        for dataset in datasets:
            print(f"   Dataset: {dataset.dataset_id}")
            print(f"   Location: {dataset.location}")
            print(f"   Created: {dataset.created}")
            
            # Check if it's an external dataset by looking for external tables
            try:
                tables = list(client.list_tables(dataset.dataset_id))
                external_tables = [t for t in tables if t.table_type == 'EXTERNAL']
                if external_tables:
                    print(f"   External tables: {len(external_tables)}")
                    for table in external_tables:
                        print(f"     - {table.table_id}")
                    external_datasets.append(dataset.dataset_id)
                else:
                    print(f"   Regular tables: {len(tables)}")
            except Exception as e:
                print(f"   Error listing tables: {str(e)}")
            
            print()
        
        return external_datasets
        
    except Exception as e:
        print(f"❌ Error listing datasets: {str(e)}")
        return []

def main():
    if len(sys.argv) != 4:
        print("Usage: python test_bigquery_omni.py <gcp_project_id> <dataset_id> <table_name>")
        print("Example: python test_bigquery_omni.py my-project glue2bq_dev_external_dataset sample_iceberg_table")
        sys.exit(1)
    
    project_id = sys.argv[1]
    dataset_id = sys.argv[2]
    table_name = sys.argv[3]
    
    print("🔍 Testing BigQuery Omni Access to Iceberg Table")
    print("=" * 50)
    
    # Create BigQuery client
    client = get_bigquery_client()
    
    # List external datasets first
    external_datasets = list_external_datasets(client, project_id)
    
    if not external_datasets:
        print("❌ No external datasets found. Make sure:")
        print("   1. BigQuery Omni connection is properly configured")
        print("   2. External dataset has been created")
        print("   3. You have the correct project ID")
        sys.exit(1)
    
    # Test table access
    success = test_table_access(client, project_id, dataset_id, table_name)
    
    if success:
        print(f"\n🎉 Success! The Iceberg table is accessible via BigQuery Omni")
        print(f"\nNext steps:")
        print(f"1. Run more complex queries to test performance")
        print(f"2. Test data filtering by date partitions")
        print(f"3. Monitor query costs in BigQuery console")
    else:
        print(f"\n❌ Failed to access the table via BigQuery Omni")
        print(f"\nTroubleshooting steps:")
        print(f"1. Check BigQuery Omni connection status")
        print(f"2. Verify IAM permissions for the connection")
        print(f"3. Ensure the external dataset is properly configured")
        print(f"4. Check that the Glue table exists and is accessible")

if __name__ == "__main__":
    main()
