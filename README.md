# Glue2BQ Terraform Project

This Terraform project creates a multi-cloud data pipeline infrastructure connecting AWS and GCP, featuring Iceberg table support and BigQuery Omni integration.

## Features

- AWS S3 bucket with CMEK encryption
- AWS Glue Catalog with CMEK encryption
- Glue database with Iceberg table support
- AWS Glue Crawler for Iceberg tables
- GCP GCS bucket with CMEK encryption
- Storage Transfer Job from S3 to GCS
- BigQuery Omni Connection to AWS with external dataset
- VPC Service Controls Service Perimeter with ingress/egress policies
- Default BigQuery dataset for local queries

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Google Cloud CLI** configured with appropriate credentials
3. **Terraform** >= 1.0 installed
4. **AWS Account** with permissions to create:
   - S3 buckets and KMS keys
   - Glue databases and tables
   - IAM roles and policies
5. **GCP Project** with permissions to create:
   - GCS buckets and KMS keys
   - BigQuery connections and datasets
   - Storage Transfer jobs
   - VPC Service Controls
   - Access Context Manager

## Setup Instructions

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and provide:
- `gcp_project_id`: Your GCP project ID
- `gcp_organization_id`: Your GCP organization ID
- `aws_region`: AWS region (default: us-east-1)
- `gcp_region`: GCP region (default: us-central1)

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. Create Iceberg Table with Sample Data

After the infrastructure is created, use the Python script in the `data/` directory to create an Iceberg table:

```bash
cd data
python3 -m pip install -r requirements.txt
python3 create_glue_iceberg.py
```

Or with custom parameters:
```bash
python3 create_glue_iceberg.py glue2bq-dev-data-bucket us-east-1 sample_iceberg_table
```

See `data/SUCCESS_SUMMARY.md` for more details on the recommended approach.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│       AWS       │    │   Storage       │    │       GCP       │
│                 │    │   Transfer      │    │                 │
│ ┌─────────────┐ │    │                 │    │ ┌─────────────┐ │
│ │ S3 Bucket   │◄┼────┼── Transfer Job  ┼────┼►│ GCS Bucket  │ │
│ │ (CMEK)      │ │    │   (IAM User)    │    │ │ (CMEK)      │ │
│ └─────────────┘ │    └─────────────────┘    │ └─────────────┘ │
│                 │                           │                 │
│ ┌─────────────┐ │                           │ ┌─────────────┐ │
│ │ Glue DB     │ │                           │ │ BigQuery    │ │
│ │             │ │                           │ │ Omni        │ │
│ │ + Crawler   │◄┼───────────────────────────┼►| + External  │ │
│ └─────────────┘ │                           │ │   Dataset   │ │
│ ┌─────────────┐ │                           │ └─────────────┘ │
│ │ Glue Catalog│ │                           │                 │
│ │ (CMEK)      │ │                           │ ┌─────────────┐ │
│ └─────────────┘ │                           │ │ VPC Service │ │
└─────────────────┘                           │ │ Perimeter   │ │
                                              │ └─────────────┘ │
                                              └─────────────────┘
```

## Key Components

### AWS Resources
- **S3 Bucket**: Encrypted with CMEK, contains Iceberg table data
- **Glue Catalog**: Encrypted with CMEK, manages metadata
- **Glue Database**: Single database (`glue2bq_dev_database`) for Iceberg tables
- **Glue Crawler**: Automated Iceberg table discovery
- **IAM Roles**: For Storage Transfer (web identity federation) and BigQuery Omni access
- **IAM User**: For Storage Transfer service with access key

### GCP Resources
- **GCS Bucket**: Encrypted with CMEK, destination for data transfer
- **Storage Transfer Job**: Transfers data from S3 to GCS using IAM user credentials
- **BigQuery Omni Connection**: Connects to AWS Glue Catalog with web identity federation
- **BigQuery External Dataset**: External dataset querying data from AWS via Omni
- **BigQuery Default Dataset**: Single-region dataset for local queries
- **VPC Service Perimeter**: Provides security boundaries with ingress (VPN) and egress (BigQuery Omni) policies
- **Access Context Manager**: Manages VPN access levels

## Security Features

- **CMEK Encryption**: All data encrypted with customer-managed keys (S3, Glue Catalog, GCS)
- **IAM Roles**: Least-privilege access with web identity federation for BigQuery Omni
- **IAM User**: For Storage Transfer with access key-based authentication
- **VPC Service Controls**: Network-level security perimeter with:
  - Ingress policy: VPN access (configurable via `vpn_ip_subnetworks`)
  - Egress policy: BigQuery Omni access to S3 bucket
- **Bucket Policies**: Restrictive access controls (public access blocked)
- **Bucket Versioning**: Enabled on both S3 and GCS buckets

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS and GCP credentials have sufficient permissions
2. **KMS Key Access**: Verify KMS key policies allow the necessary services
3. **Cross-Account Access**: Check that IAM roles have correct trust relationships
4. **VPC Service Controls**: May take several minutes to activate

### Useful Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check GCP credentials
gcloud auth list

# Validate Terraform configuration
terraform validate

# View current state
terraform show

# Check Glue databases
aws glue get-databases

# Check Glue tables
aws glue get-tables --database-name glue2bq-dev_database

# List S3 bucket contents
aws s3 ls s3://glue2bq-dev-data-bucket/ --recursive

# Query BigQuery external dataset
bq query --use_legacy_sql=false 'SELECT COUNT(*) FROM `project-id.glue2bq_dev_external_dataset.sample_iceberg_table`'

# Destroy infrastructure (when done)
terraform destroy
```

## Outputs

After successful deployment, Terraform will output:
- S3 bucket name and ARN
- S3 CMEK ARN
- Glue database name and ARN
- Glue Catalog CMEK ARN
- Storage Transfer role ARN
- BigQuery Omni role ARN
- GCS bucket name
- GCS CMEK name
- BigQuery Omni connection name
- BigQuery external dataset ID
- VPC Service Perimeter name

## Next Steps

1. **Create Iceberg Tables**: Use the scripts in `data/` directory to populate with sample data
2. **Run Glue Crawler**: Execute the crawler to discover Iceberg tables
3. **Test BigQuery Omni**: Query the external datasets in BigQuery
4. **Test Storage Transfer**: Manually trigger or wait for scheduled transfer
5. **Configure VPN Access**: Update `vpn_ip_subnetworks` variable with your VPN ranges
6. **Monitor Security**: Check VPC Service Controls violations and logs

## Directory Structure

```
.
├── main.tf                          # Provider configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── aws-resources.tf                 # S3, KMS keys
├── aws-glue.tf                      # Glue databases
├── aws-glue-crawler.tf              # Glue crawler and IAM roles
├── storage-transfer.tf              # Storage Transfer job and IAM
├── bigquery-omni.tf                 # BigQuery Omni connection and datasets
├── gcp-resources.tf                 # GCS bucket, KMS
├── vpc-service-controls.tf          # VPC Service Perimeter and access policies
├── terraform.tfvars.example         # Example variables file
└── data/                            # Helper scripts for Iceberg tables
    ├── create_glue_iceberg.py      # Create Iceberg table (recommended)
    ├── create_iceberg_spark.py      # Alternative: using Spark
    ├── create_iceberg_simple.py     # Alternative: using PyIceberg
    ├── test_bigquery_omni.py        # Test BigQuery Omni access
    ├── requirements.txt             # Python dependencies
    ├── ICEBERG_GUIDE.md             # Comprehensive guide for Iceberg tables
    └── SUCCESS_SUMMARY.md           # Summary of successful approach
```

## Cost Considerations

- S3 storage and requests
- Glue Catalog metadata operations
- GCS storage and operations (with lifecycle rules to Nearline after 7 days)
- BigQuery Omni query costs
- Storage Transfer job costs
- VPC Service Controls costs
- KMS key usage and operations

Monitor usage in both AWS and GCP consoles to track costs.

## Additional Resources

- **Creating Iceberg Tables**: See `data/ICEBERG_GUIDE.md` for detailed instructions
- **Successful Approach**: See `data/SUCCESS_SUMMARY.md` for the recommended method
- **Testing**: Use `data/test_bigquery_omni.py` to verify BigQuery Omni connectivity

## Known Limitations

- Storage Transfer uses IAM user/access key instead of web identity federation
- VPC Service Perimeter ingress/egress policies are defined in Terraform (not using Violations Analyzer)
- VPN subnetworks must be provided via `vpn_ip_subnetworks` variable
