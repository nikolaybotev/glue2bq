# Glue2BQ Terraform Project

This Terraform project creates a multi-cloud data pipeline infrastructure connecting AWS and GCP, featuring:

- AWS S3 bucket with CMEK encryption
- AWS Glue Catalog with CMEK encryption
- Glue database with Iceberg table support
- GCP GCS bucket with CMEK encryption
- Storage Transfer Job from S3 to GCS
- BigQuery Omni Connection to AWS
- VPC Service Controls Service Perimeter

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

After the infrastructure is created, run the script to populate the S3 bucket with sample Iceberg data:

```bash
./create_iceberg_table.sh
```

Or with custom parameters:
```bash
./create_iceberg_table.sh your-bucket-name us-east-1
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│       AWS       │    │   Storage       │    │       GCP       │
│                 │    │   Transfer      │    │                 │
│ ┌─────────────┐ │    │                 │    │ ┌─────────────┐ │
│ │ S3 Bucket   │◄┼────┼─► Transfer Job  ─┼───►│ │ GCS Bucket  │ │
│ │ (CMEK)      │ │    │                 │    │ │ (CMEK)      │ │
│ └─────────────┘ │    └─────────────────┘    │ └─────────────┘ │
│                 │                            │                 │
│ ┌─────────────┐ │                            │ ┌─────────────┐ │
│ │ Glue DB     │ │                            │ │ BigQuery    │ │
│ │ (CMEK)      │◄┼────────────────────────────┼─► Omni       │ │
│ └─────────────┘ │                            │ │ Connection  │ │
└─────────────────┘                            │ └─────────────┘ │
                                               └─────────────────┘
```

## Key Components

### AWS Resources
- **S3 Bucket**: Encrypted with CMEK, contains Iceberg table data
- **Glue Catalog**: Encrypted with CMEK, manages metadata
- **Glue Database**: Points to Iceberg tables in S3
- **IAM Roles**: For Storage Transfer and BigQuery Omni access

### GCP Resources
- **GCS Bucket**: Encrypted with CMEK, destination for data transfer
- **Storage Transfer Job**: Transfers data from S3 to GCS
- **BigQuery Omni Connection**: Connects to AWS Glue Catalog
- **BigQuery External Dataset**: Queries data from AWS via Omni
- **VPC Service Perimeter**: Provides security boundaries

## Security Features

- **CMEK Encryption**: All data encrypted with customer-managed keys
- **IAM Roles**: Least-privilege access with web identity federation
- **VPC Service Controls**: Network-level security perimeter
- **Bucket Policies**: Restrictive access controls

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

# Destroy infrastructure (when done)
terraform destroy
```

## Outputs

After successful deployment, Terraform will output:
- S3 bucket name and ARN
- Glue database name and ARN
- GCS bucket name
- BigQuery Omni connection name
- VPC Service Perimeter name
- Various KMS key ARNs

## Next Steps

1. Configure access levels and ingress/egress rules in the VPC Service Perimeter via GCP Console
2. Test the Storage Transfer Job
3. Query the external dataset in BigQuery
4. Monitor security and access logs

## Cost Considerations

- S3 storage and requests
- Glue Catalog metadata operations
- GCS storage and operations
- BigQuery Omni query costs
- Storage Transfer job costs
- VPC Service Controls costs

Monitor usage in both AWS and GCP consoles to track costs.
